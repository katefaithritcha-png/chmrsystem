import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/common_models.dart';
import 'audit_service.dart';

class PatientService {
  PatientService._internal();
  static final PatientService instance = PatientService._internal();
  factory PatientService() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('patients');

  

  Future<List<PatientRecord>> fetchPatients() async {
    final snap = await _col.get();
    return snap.docs.map((d) {
      final data = d.data();
      return PatientRecord.fromJson({
        'id': (data['id'] ?? d.id) as String,
        'name': (data['name'] ?? '') as String,
        'age': (data['age'] ?? 0) as int,
        'sex': (data['sex'] ?? '') as String,
        'diagnosis': (data['diagnosis'] ?? '') as String,
      });
    }).toList();
  }

  Future<PatientRecord> addPatient(
      String name, int age, String sex, String diagnosis) async {
    final doc = _col.doc();
    final rec = PatientRecord(
        id: doc.id, name: name, age: age, sex: sex, diagnosis: diagnosis);
    await doc.set({
      ...rec.toJson(),
      'nameLower': name.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await AuditService.instance.addEvent(
      action: 'patient.create',
      target: 'patients/${doc.id}',
      details: 'name=$name, age=$age, sex=$sex',
      level: 'info',
    );
    return rec;
  }

  Future<PatientRecord> updatePatient(String id,
      {String? name, int? age, String? sex, String? diagnosis}) async {
    final updates = <String, Object?>{};
    if (name != null) {
      updates['name'] = name;
      updates['nameLower'] = name.toLowerCase();
    }
    if (age != null) updates['age'] = age;
    if (sex != null) updates['sex'] = sex;
    if (diagnosis != null) updates['diagnosis'] = diagnosis;
    if (updates.isEmpty) {
      final cur = await _col.doc(id).get();
      if (!cur.exists) throw StateError('Patient not found');
      final data = cur.data()!;
      return PatientRecord.fromJson({
        'id': (data['id'] ?? id) as String,
        'name': (data['name'] ?? '') as String,
        'age': (data['age'] ?? 0) as int,
        'sex': (data['sex'] ?? '') as String,
        'diagnosis': (data['diagnosis'] ?? '') as String,
      });
    }
    await _col.doc(id).set(updates, SetOptions(merge: true));
    await AuditService.instance.addEvent(
      action: 'patient.update',
      target: 'patients/$id',
      details: updates.toString(),
      level: 'info',
    );
    final cur = await _col.doc(id).get();
    final data = cur.data() ?? {};
    return PatientRecord.fromJson({
      'id': (data['id'] ?? id) as String,
      'name': (data['name'] ?? '') as String,
      'age': (data['age'] ?? 0) as int,
      'sex': (data['sex'] ?? '') as String,
      'diagnosis': (data['diagnosis'] ?? '') as String,
    });
  }

  Future<void> deletePatient(String id) async {
    await _col.doc(id).delete();
    await AuditService.instance.addEvent(
      action: 'patient.delete',
      target: 'patients/$id',
      level: 'warning',
    );
  }

  

  Future<void> resetAll() async {
    // Danger: destructive. Deletes all patient documents.
    final snap = await _col.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    
    await AuditService.instance.addEvent(
      action: 'patient.reset_all',
      target: 'patients',
      details: 'count=${snap.size}',
      level: 'warning',
    );
  }
}
