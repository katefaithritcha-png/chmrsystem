import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/common_models.dart';
import 'audit_service.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<AppUser>> fetchUsers() async {
    final snap = await _db.collection('users').orderBy('createdAt', descending: true).limit(500).get();
    return snap.docs.map((d) {
      final m = d.data();
      return AppUser(
        id: d.id,
        name: (m['name'] ?? '') as String,
        role: (m['role'] ?? 'patient') as String,
        email: (m['email'] ?? '') as String,
      );
    }).toList();
  }

  Future<AppUser> addUser(String name, String role, String email) async {
    final doc = _db.collection('users').doc();
    await doc.set({
      'name': name,
      'role': role,
      'email': email.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AuditService.instance.addEvent(
      action: 'user.create',
      target: 'users/${doc.id}',
      details: 'name=$name, role=$role, email=$email',
      level: 'info',
    );
    return AppUser(id: doc.id, name: name, role: role, email: email.toLowerCase());
  }

  Future<AppUser> updateUser(String id, {String? name, String? role, String? email}) async {
    final updates = <String, Object?>{};
    if (name != null) updates['name'] = name;
    if (role != null) updates['role'] = role;
    if (email != null) updates['email'] = email.toLowerCase();
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(id).set(updates, SetOptions(merge: true));
      await AuditService.instance.addEvent(
        action: 'user.update',
        target: 'users/$id',
        details: updates.toString(),
        level: 'info',
      );
    }
    final cur = await _db.collection('users').doc(id).get();
    final m = cur.data() ?? {};
    return AppUser(
      id: id,
      name: (m['name'] ?? name ?? '') as String,
      role: (m['role'] ?? role ?? 'patient') as String,
      email: (m['email'] ?? email ?? '') as String,
    );
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
    await AuditService.instance.addEvent(
      action: 'user.delete',
      target: 'users/$id',
      level: 'warning',
    );
  }
}
