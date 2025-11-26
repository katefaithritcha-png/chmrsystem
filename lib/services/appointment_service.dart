import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'audit_service.dart';
import 'patient_service.dart';

enum ApptStatus { pending, confirmed, completed, declined }

class Appointment {
  Appointment({
    required this.id,
    required this.date,
    required this.purpose,
    required this.status,
    required this.patientName,
  });

  String id;
  String date;
  String purpose;
  ApptStatus status;
  String patientName;
}

class AppointmentService extends ChangeNotifier {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final List<Appointment> _items = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  // Start a snapshot listener once to keep local cache in sync
  bool _listening = false;
  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    _col.orderBy('createdAt', descending: true).snapshots().listen((snap) {
      _items
        ..clear()
        ..addAll(snap.docs.map((d) {
          final data = d.data();
          return Appointment(
            id: d.id,
            date: (data['date'] ?? '') as String,
            purpose: (data['purpose'] ?? '') as String,
            status: _parseStatus((data['status'] ?? 'pending') as String),
            patientName: (data['patientName'] ?? '') as String,
          );
        }));
      notifyListeners();
    });
  }

  /// One-shot refresh for UI retry/pull-to-refresh.
  Future<void> refresh() async {
    _ensureListening();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await _col
          .where('createdBy', isEqualTo: uid)
          .orderBy('date', descending: false)
          .get();
      final fresh = snap.docs.map((d) {
        final m = d.data();
        final statusStr = (m['status'] ?? 'pending').toString();
        ApptStatus st;
        switch (statusStr) {
          case 'confirmed':
            st = ApptStatus.confirmed;
            break;
          case 'completed':
            st = ApptStatus.completed;
            break;
          case 'declined':
            st = ApptStatus.declined;
            break;
          default:
            st = ApptStatus.pending;
        }
        return Appointment(
          id: d.id,
          date: (m['date'] ?? '').toString(),
          purpose: (m['purpose'] ?? '').toString(),
          status: st,
          patientName: (m['patientName'] ?? '').toString(),
        );
      }).toList();
      _items
        ..clear()
        ..addAll(fresh);
      notifyListeners();
    } catch (_) {
      // leave cache as-is on failure
    }
  }

  List<Appointment> get items {
    _ensureListening();
    return List.unmodifiable(_items);
  }

  List<Appointment> pending() =>
      items.where((e) => e.status == ApptStatus.pending).toList();

  Future<void> create(
      {required String date,
      required String purpose,
      required String patientName,
      String? notes}) async {
    _ensureListening();
    final user = FirebaseAuth.instance.currentUser;
    // Normalize a Timestamp for ordering while keeping display string
    Timestamp? dateTs;
    try {
      final dt = DateFormat('yyyy-MM-dd h:mm a').parse(date);
      dateTs = Timestamp.fromDate(dt);
    } catch (_) {
      try {
        final dt = DateTime.parse(date);
        dateTs = Timestamp.fromDate(dt);
      } catch (_) {}
    }
    await _col.add({
      'date': date,
      if (dateTs != null) 'dateTs': dateTs,
      'purpose': purpose,
      'status': 'pending',
      'patientName': patientName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdBy': user?.uid,
      'createdByEmail': user?.email?.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await AuditService.instance.addEvent(
      actorId: user?.uid,
      actorRole: 'patient',
      action: 'appointment.create',
      target: 'appointments',
      details: 'date=$date, purpose=$purpose, patientName=$patientName',
      level: 'info',
    );
    // Create patient update for the requester
    if (user?.uid != null) {
      await FirebaseFirestore.instance.collection('patient_updates').add({
        'recipientId': user!.uid,
        'message': 'Your appointment request is pending approval.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'appointment',
      });
      await AuditService.instance.addEvent(
        actorId: user.uid,
        actorRole: 'system',
        action: 'appointment.notify_pending',
        target: 'patient_updates',
        details: 'to=${user.uid}',
        level: 'info',
      );
    }
  }

  Future<void> approve(String id) async {
    await _col.doc(id).set({'status': 'confirmed'}, SetOptions(merge: true));
    final approver = FirebaseAuth.instance.currentUser?.uid;
    await AuditService.instance.addEvent(
      actorId: approver,
      actorRole: 'health_worker',
      action: 'appointment.approve',
      target: 'appointments/$id',
      level: 'info',
    );
    final doc = await _col.doc(id).get();
    final data = doc.data();
    final recipientId = data?['createdBy'] as String?;
    final date = (data?['date'] ?? '') as String;
    if (recipientId != null) {
      await FirebaseFirestore.instance.collection('patient_updates').add({
        'recipientId': recipientId,
        'message': 'Your appointment on $date has been confirmed.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'appointment',
      });
      await AuditService.instance.addEvent(
        actorId: approver,
        actorRole: 'health_worker',
        action: 'appointment.notify_confirmed',
        target: 'patient_updates',
        details: 'to=$recipientId, date=$date',
        level: 'info',
      );
    }

    // Ensure a PatientRecord exists and link it to this appointment
    try {
      final currentPatientRecordId = (data?['patientRecordId'] ?? '') as String;
      if (currentPatientRecordId.isEmpty) {
        final name = (data?['patientName'] ?? 'Patient').toString();
        final purpose = (data?['purpose'] ?? 'Check-up').toString();
        final rec =
            await PatientService.instance.addPatient(name, 0, 'U', purpose);
        await _col
            .doc(id)
            .set({'patientRecordId': rec.id}, SetOptions(merge: true));
      }
    } catch (e, st) {
      debugPrint('approve.ensurePatientRecord error: $e\n$st');
    }
  }

  Future<void> decline(String id) async {
    await _col.doc(id).set({'status': 'declined'}, SetOptions(merge: true));
    final actor = FirebaseAuth.instance.currentUser?.uid;
    await AuditService.instance.addEvent(
      actorId: actor,
      actorRole: 'health_worker',
      action: 'appointment.decline',
      target: 'appointments/$id',
      level: 'warning',
    );
    final doc = await _col.doc(id).get();
    final data = doc.data();
    final recipientId = data?['createdBy'] as String?;
    final date = (data?['date'] ?? '') as String;
    if (recipientId != null) {
      await FirebaseFirestore.instance.collection('patient_updates').add({
        'recipientId': recipientId,
        'message': 'Your appointment on $date has been declined.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'appointment',
      });
      await AuditService.instance.addEvent(
        actorId: actor,
        actorRole: 'health_worker',
        action: 'appointment.notify_declined',
        target: 'patient_updates',
        details: 'to=$recipientId, date=$date',
        level: 'info',
      );
    }
  }

  Future<void> complete(String id) async {
    await _col.doc(id).set({'status': 'completed'}, SetOptions(merge: true));
    final actor = FirebaseAuth.instance.currentUser?.uid;
    await AuditService.instance.addEvent(
      actorId: actor,
      actorRole: 'health_worker',
      action: 'appointment.complete',
      target: 'appointments/$id',
      level: 'info',
    );
    final doc = await _col.doc(id).get();
    final data = doc.data();
    final recipientId = data?['createdBy'] as String?;
    final date = (data?['date'] ?? '') as String;
    if (recipientId != null) {
      await FirebaseFirestore.instance.collection('patient_updates').add({
        'recipientId': recipientId,
        'message': 'Your appointment on $date was marked completed.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'appointment',
      });
      await AuditService.instance.addEvent(
        actorId: actor,
        actorRole: 'health_worker',
        action: 'appointment.notify_completed',
        target: 'patient_updates',
        details: 'to=$recipientId, date=$date',
        level: 'info',
      );
    }
  }

  ApptStatus _parseStatus(String v) {
    switch (v) {
      case 'confirmed':
        return ApptStatus.confirmed;
      case 'completed':
        return ApptStatus.completed;
      case 'declined':
        return ApptStatus.declined;
      default:
        return ApptStatus.pending;
    }
  }
}
