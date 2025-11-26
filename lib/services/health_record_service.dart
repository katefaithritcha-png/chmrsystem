import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthRecordService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addRecord({
    required Map<String, dynamic> record,
    String? patientId,
  }) async {
    try {
      final String? effectivePatientId =
          patientId ?? FirebaseAuth.instance.currentUser?.uid;
      final data = Map<String, dynamic>.from(record)
        ..addAll({
          'createdAt': FieldValue.serverTimestamp(),
          if (effectivePatientId != null) 'patientId': effectivePatientId,
        });
      final ref = await _db.collection('patient_records').add(data);
      return ref.id;
    } catch (e, st) {
      debugPrint('HealthRecordService.addRecord error: $e\n$st');
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllRecords(
      {int limit = 200}) {
    return _db
        .collection('patient_records')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyRecords(
      {int limit = 200}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _db
        .collection('patient_records')
        .where('patientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> updateRecord(String id, Map<String, dynamic> updates) async {
    try {
      await _db
          .collection('patient_records')
          .doc(id)
          .set(updates, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('HealthRecordService.updateRecord error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _db.collection('patient_records').doc(id).delete();
    } catch (e, st) {
      debugPrint('HealthRecordService.deleteRecord error: $e\n$st');
      rethrow;
    }
  }
}
