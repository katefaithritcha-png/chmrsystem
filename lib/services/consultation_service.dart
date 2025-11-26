import 'package:cloud_firestore/cloud_firestore.dart';
import 'audit_service.dart';

class ConsultationService {
  ConsultationService._();
  static final ConsultationService instance = ConsultationService._();
  factory ConsultationService() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('consultations');

  // KPI streams
  Stream<int> inQueueCount() {
    return _col
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> inProgressCount() {
    try {
      return _col
          .where('status',
              whereIn: ['in_progress', 'in-progress', 'in progress'])
          .snapshots()
          .map((s) => s.size);
    } catch (_) {
      return _col
          .where('status', isEqualTo: 'in_progress')
          .snapshots()
          .map((s) => s.size);
    }
  }

  // Live list of in-progress consultations
  Stream<List<Map<String, Object>>> inProgressStream() {
    return _col
        .where('status', isEqualTo: 'in_progress')
        .snapshots()
        .map((snap) {
      final items = snap.docs.map((d) {
        final x = d.data();
        final ts = x['startedAt'];
        final dt = ts is Timestamp
            ? ts.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final startedText = ts is Timestamp
            ? dt.toLocal().toString()
            : (x['startedAt'] ?? '') as String;
        return {
          'docId': d.id,
          'id': (x['patientId'] ?? '') as String,
          'name': (x['patientName'] ?? '') as String,
          'reason': (x['reason'] ?? '') as String,
          'started': startedText,
          '_sort': dt.millisecondsSinceEpoch,
        };
      }).toList();
      items.sort((a, b) => (b['_sort'] as int).compareTo(a['_sort'] as int));
      return items
          .map((m) => {
                'docId': m['docId'] as String,
                'id': m['id'] as String,
                'name': m['name'] as String,
                'reason': m['reason'] as String,
                'started': m['started'] as String,
              })
          .toList();
    });
  }

  /// One-shot fetch of in-progress consultations, sorted by startedAt desc.
  Future<List<Map<String, Object>>> fetchInProgressOnce() async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _col.where('status',
          whereIn: ['in_progress', 'in-progress', 'in progress']).get();
    } catch (_) {
      snap = await _col.where('status', isEqualTo: 'in_progress').get();
    }
    final items = snap.docs.map((d) {
      final x = d.data();
      final ts = x['startedAt'];
      final dt = ts is Timestamp
          ? ts.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      final startedText = ts is Timestamp
          ? dt.toLocal().toString()
          : (x['startedAt'] ?? '') as String;
      return {
        'docId': d.id,
        'id': (x['patientId'] ?? '') as String,
        'name': (x['patientName'] ?? '') as String,
        'reason': (x['reason'] ?? '') as String,
        'started': startedText,
        '_sort': dt.millisecondsSinceEpoch,
      };
    }).toList();
    items.sort((a, b) => (b['_sort'] as int).compareTo(a['_sort'] as int));
    return items
        .map((m) => {
              'docId': m['docId'] as String,
              'id': m['id'] as String,
              'name': m['name'] as String,
              'reason': m['reason'] as String,
              'started': m['started'] as String,
            })
        .toList();
  }

  Stream<int> todayDoneCount() {
    final start = DateTime.now();
    final startOfDay = DateTime(start.year, start.month, start.day);
    return _col
        .where('status', isEqualTo: 'completed')
        .where('endedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((s) => s.size);
  }

  // Queue stream (pending)
  Stream<List<Map<String, Object>>> queueStream() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final x = d.data();
              return <String, Object>{
                'docId': d.id,
                'id': (x['patientId'] ?? '') as String,
                'name': (x['patientName'] ?? '') as String,
                'reason': (x['reason'] ?? '') as String,
                'time': (x['time'] ?? '') as String,
              };
            }).toList());
  }

  // Recent completed consultations
  Stream<List<Map<String, Object>>> recentStream({int limit = 10}) {
    return _col
        .where('status', isEqualTo: 'completed')
        .orderBy('endedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final x = d.data();
              final endedAt = (x['endedAt'] is Timestamp)
                  ? (x['endedAt'] as Timestamp).toDate().toLocal().toString()
                  : (x['endedAt'] ?? '') as String;
              return <String, Object>{
                'docId': d.id,
                'id': (x['patientId'] ?? '') as String,
                'name': (x['patientName'] ?? '') as String,
                'dx': (x['diagnosis'] ?? '') as String,
                'when': endedAt,
              };
            }).toList());
  }

  Future<void> startConsultation(String docId) async {
    await _col.doc(docId).set(
        {'status': 'in_progress', 'startedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
    await AuditService.instance.addEvent(
      action: 'consultation.start',
      target: 'consultations/$docId',
      level: 'info',
    );
  }

  Future<void> completeConsultation(
    String docId, {
    required String diagnosis,
    String? complaint,
    String? vitals,
    String? plan,
  }) async {
    await _col.doc(docId).set(
      {
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
        'diagnosis': diagnosis,
        if (complaint != null) 'complaint': complaint,
        if (vitals != null) 'vitals': vitals,
        if (plan != null) 'plan': plan,
      },
      SetOptions(merge: true),
    );
    await AuditService.instance.addEvent(
      action: 'consultation.complete',
      target: 'consultations/$docId',
      details: 'dx=$diagnosis',
      level: 'info',
    );
  }

  Future<String> addToQueue(
      {required String patientId,
      required String patientName,
      required String reason}) async {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final doc = await _col.add({
      'patientId': patientId,
      'patientName': patientName,
      'reason': reason,
      'time': '$hh:$mm',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await AuditService.instance.addEvent(
      action: 'consultation.queue_add',
      target: 'consultations/${doc.id}',
      details: 'pid=$patientId name=$patientName',
      level: 'info',
    );
    return doc.id;
  }

  Future<void> removeFromQueue(String docId) async {
    await _col.doc(docId).delete();
    await AuditService.instance.addEvent(
      action: 'consultation.remove_from_queue',
      target: 'consultations/$docId',
      level: 'warning',
    );
  }
}
