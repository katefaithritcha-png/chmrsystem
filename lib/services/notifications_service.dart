import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/common_models.dart';
import 'audit_service.dart';

class NotificationsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<AppNotification>> fetchNotifications(
      {String role = 'patient'}) async {
    try {
      Query query = _db.collection('patient_updates');
      if (role == 'patient') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return [];
        query = query.where('recipientId', isEqualTo: uid);
      }
      final snap = await query.limit(200).get();
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        final ts = data['createdAt'];
        final dt = ts is Timestamp
            ? ts.toDate()
            : DateTime.tryParse('${ts ?? ''}') ?? DateTime.now();
        return AppNotification(
          id: d.id,
          message: (data['message'] ?? data['title'] ?? 'Update').toString(),
          read: (data['read'] as bool?) ?? false,
          time: dt,
          archived: (data['archived'] as bool?) ?? false,
        );
      }).toList()
        ..sort((a, b) => b.time.compareTo(a.time));
    } catch (e, st) {
      debugPrint('NotificationsService.fetchNotifications error: $e\n$st');
      rethrow;
    }
  }

  Future<void> markRead(String id, bool read) async {
    try {
      await _db.collection('patient_updates').doc(id).update({'read': read});
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await AuditService.instance.addEvent(
        actorId: uid,
        actorRole: 'user',
        action: read ? 'notification.mark_read' : 'notification.mark_unread',
        target: 'patient_updates/$id',
        level: 'info',
      );
    } catch (e, st) {
      debugPrint('NotificationsService.markRead error: $e\n$st');
      rethrow;
    }
  }

  Future<void> markAllRead({String role = 'patient'}) async {
    try {
      WriteBatch batch = _db.batch();
      Query query =
          _db.collection('patient_updates').where('read', isEqualTo: false);
      if (role == 'patient') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        query = query.where('recipientId', isEqualTo: uid);
      }
      final snap = await query.get();
      for (final d in snap.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await AuditService.instance.addEvent(
        actorId: uid,
        actorRole: role,
        action: 'notification.mark_all_read',
        target: 'patient_updates',
        details: 'count=${snap.size}',
        level: 'info',
      );
    } catch (e, st) {
      debugPrint('NotificationsService.markAllRead error: $e\n$st');
      rethrow;
    }
  }

  Future<void> clearAll({String role = 'patient'}) async {
    try {
      WriteBatch batch = _db.batch();
      Query query = _db.collection('patient_updates');
      if (role == 'patient') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        query = query.where('recipientId', isEqualTo: uid);
      }
      final snap = await query.get();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await AuditService.instance.addEvent(
        actorId: uid,
        actorRole: role,
        action: 'notification.clear_all',
        target: 'patient_updates',
        details: 'count=${snap.size}',
        level: 'warning',
      );
    } catch (e, st) {
      debugPrint('NotificationsService.clearAll error: $e\n$st');
      rethrow;
    }
  }

  Future<void> setArchived(String id, bool archived) async {
    try {
      await _db
          .collection('patient_updates')
          .doc(id)
          .set({'archived': archived}, SetOptions(merge: true));
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await AuditService.instance.addEvent(
        actorId: uid,
        actorRole: 'user',
        action: archived ? 'notification.archive' : 'notification.unarchive',
        target: 'patient_updates/$id',
        level: 'info',
      );
    } catch (e, st) {
      debugPrint('NotificationsService.setArchived error: $e\n$st');
      rethrow;
    }
  }

  Future<void> deleteOne(String id) async {
    try {
      await _db.collection('patient_updates').doc(id).delete();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await AuditService.instance.addEvent(
        actorId: uid,
        actorRole: 'user',
        action: 'notification.delete',
        target: 'patient_updates/$id',
        level: 'warning',
      );
    } catch (e, st) {
      debugPrint('NotificationsService.deleteOne error: $e\n$st');
      rethrow;
    }
  }

  Future<void> archiveAllUnread({String role = 'patient'}) async {
    try {
      WriteBatch batch = _db.batch();
      Query query =
          _db.collection('patient_updates').where('read', isEqualTo: false);
      if (role == 'patient') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        query = query.where('recipientId', isEqualTo: uid);
      }
      final snap = await query.get();
      for (final d in snap.docs) {
        batch.set(d.reference, {'archived': true}, SetOptions(merge: true));
      }
      await batch.commit();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await AuditService.instance.addEvent(
        actorId: uid,
        actorRole: role,
        action: 'notification.archive_all_unread',
        target: 'patient_updates',
        details: 'count=${snap.size}',
        level: 'info',
      );
    } catch (e, st) {
      debugPrint('NotificationsService.archiveAllUnread error: $e\n$st');
      rethrow;
    }
  }
}
