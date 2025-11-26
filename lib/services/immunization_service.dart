import 'package:cloud_firestore/cloud_firestore.dart';

class ImmunizationService {
  ImmunizationService._();
  static final ImmunizationService instance = ImmunizationService._();
  factory ImmunizationService() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('immunization_followups');

  // Missed follow-ups: dueDate <= now and status != completed
  Stream<int> missedCount() {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('dueDate', isLessThanOrEqualTo: now)
        .where('status', isNotEqualTo: 'completed')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<List<Map<String, Object>>> missedList({int limit = 20}) {
    final now = Timestamp.fromDate(DateTime.now());
    return _col
        .where('dueDate', isLessThanOrEqualTo: now)
        .where('status', isNotEqualTo: 'completed')
        .orderBy('dueDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final x = d.data();
              final due = x['dueDate'] is Timestamp
                  ? (x['dueDate'] as Timestamp).toDate().toLocal().toString()
                  : (x['dueDate'] ?? '') as String;
              return <String, Object>{
                'docId': d.id,
                'patientId': (x['patientId'] ?? '') as String,
                'patientName': (x['patientName'] ?? '') as String,
                'detail': (x['detail'] ?? '') as String,
                'due': due,
                'status': (x['status'] ?? '') as String,
              };
            }).toList());
  }
}
