import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthAlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamActiveAlerts() {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('alerts')
        .where('status', isEqualTo: 'ACTIVE')
        .where('startAt', isLessThanOrEqualTo: now)
        .orderBy('startAt', descending: true)
        .snapshots();
  }

  // Stream all alerts for the Bulletin Board (ongoing, upcoming, past)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllAlertsForBoard() {
    return _db
        .collection('alerts')
        .orderBy('startAt', descending: true)
        .snapshots();
  }

  Future<void> createAlert(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    await _db.collection('alerts').add({
      ...data,
      'createdByUid': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAlertRead(String alertId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref =
        _db.collection('alerts').doc(alertId).collection('userStatus').doc(uid);
    await ref.set({
      'userId': uid,
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
