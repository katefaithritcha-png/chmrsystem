import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// CHRMS Notification & Alert service
/// Stores alerts in a dedicated `chrms_alerts` collection.
class ChrmsAlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('chrms_alerts');

  /// Create a new alert document.
  ///
  /// Expected fields in [data]:
  /// - title, message
  /// - category (HEALTH_ADVISORY, IMMUNIZATION, MEDICINE, BARANGAY, EMERGENCY, APPOINTMENT, WORKER)
  /// - targetMode (ALL, GROUP, HOUSEHOLD, INDIVIDUAL, WORKERS)
  /// - targetGroups, targetHouseholdId, targetUserIds
  /// - priority (NORMAL, IMPORTANT, URGENT)
  /// - expiresAt (Timestamp)
  /// - attachments (List<String> URLs)
  Future<void> createAlert(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    await _col.add({
      ...data,
      'createdByUid': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream all alerts (for admin/workers / notification center).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllAlerts() {
    return _col.orderBy('createdAt', descending: true).snapshots();
  }

  /// Stream active (non-expired) alerts.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamActiveAlerts() {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .snapshots();
  }
}
