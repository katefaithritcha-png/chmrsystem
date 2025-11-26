import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/common_models.dart';

class AuditService {
  AuditService._internal();
  static final AuditService instance = AuditService._internal();
  factory AuditService() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addEvent({
    // New preferred fields
    String? actorId,
    String? actorRole,
    // Back-compat single actor string (e.g., 'user:123')
    String? actor,
    required String action,
    String? target,
    String? details,
    String level = 'info',
  }) async {
    // Back-compat mapping
    if ((actorId == null || actorId.isEmpty) && actor != null && actor.isNotEmpty) {
      // Try to split role:id if provided, else store the whole string as id
      final parts = actor.split(':');
      if (parts.length >= 2) {
        actorRole = actorRole ?? parts.first;
        actorId = parts.sublist(1).join(':');
      } else {
        actorId = actor;
      }
    }
    actorId = actorId ?? 'unknown';
    actorRole = actorRole ?? 'unknown';
    final ref = _db.collection('audit').doc();
    await ref.set({
      'actorId': actorId,
      'actorRole': actorRole,
      'action': action,
      'target': target,
      'details': details,
      'level': level,
      'at': FieldValue.serverTimestamp(),
    });
  }

  Query<Map<String, dynamic>> buildQuery({
    String level = 'all',
    String? actorId,
    String? action,
    DateTime? start,
    DateTime? end,
  }) {
    Query<Map<String, dynamic>> q = _db.collection('audit');
    if (level != 'all') q = q.where('level', isEqualTo: level);
    if (actorId != null && actorId.isNotEmpty) q = q.where('actorId', isEqualTo: actorId);
    if (action != null && action.isNotEmpty) q = q.where('action', isEqualTo: action);
    if (start != null) q = q.where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    if (end != null) q = q.where('at', isLessThanOrEqualTo: Timestamp.fromDate(end));
    return q.orderBy('at', descending: true).limit(500);
  }

  Stream<List<AuditEvent>> streamLogs({String level = 'all', String? actorId, String? action, DateTime? start, DateTime? end}) {
    final q = buildQuery(level: level, actorId: actorId, action: action, start: start, end: end);
    return q.snapshots().map((s) => s.docs.map((d) {
          final m = d.data();
          final ts = m['at'];
          final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
          return AuditEvent(
            id: d.id,
            actor: '${m['actorRole'] ?? ''}:${m['actorId'] ?? ''}',
            action: (m['action'] ?? '').toString(),
            level: (m['level'] ?? 'info').toString(),
            time: dt,
          );
        }).toList());
  }

  /// Clears audit logs matching the given filters. Returns number of deleted documents.
  Future<int> clearLogs({String level = 'all', String? actorId, String? action, DateTime? start, DateTime? end}) async {
    int totalDeleted = 0;
    // buildQuery already orders and limits to 500; keep fetching until empty
    while (true) {
      final snap = await buildQuery(level: level, actorId: actorId, action: action, start: start, end: end).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      totalDeleted += snap.docs.length;
      // Continue loop to delete next page if any remain
    }
    return totalDeleted;
  }

  Future<List<AuditEvent>> fetchLogs({String level = 'all', String query = ''}) async {
    // Simple one-shot fetch of recent logs, filter in memory for search
    final snap = await _db
        .collection('audit')
        .orderBy('at', descending: true)
        .limit(500)
        .get();
    final list = snap.docs.map((d) {
      final m = d.data();
      final ts = m['at'];
      final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
      return AuditEvent(
        id: d.id,
        actor: '${m['actorRole'] ?? ''}:${m['actorId'] ?? ''}',
        action: (m['action'] ?? '').toString(),
        level: (m['level'] ?? 'info').toString(),
        time: dt,
      );
    }).toList();
    Iterable<AuditEvent> res = list;
    if (level != 'all') res = res.where((e) => e.level == level);
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      res = res.where((e) => e.actor.toLowerCase().contains(q) || e.action.toLowerCase().contains(q));
    }
    return res.toList();
  }
}

