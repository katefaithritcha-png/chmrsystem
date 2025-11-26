import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> loginUser(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user?.uid;
      if (uid == null) return 'invalid';
      final signedInEmail = cred.user?.email?.toLowerCase();
      // Immediate fallback: if this is the designated admin email, route as admin even if Firestore fails
      if (signedInEmail == 'katefaithritcha@gmail.com') {
        // Best-effort: sync role to Firestore, ignore errors
        try {
          await _db.collection('users').doc(uid).set({
            'email': signedInEmail,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
        return 'admin';
      }

      var role = await _fetchUserRole(uid);
      // Enforce: only the specified email can access admin
      if (role == 'admin' && signedInEmail != 'katefaithritcha@gmail.com') {
        await _auth.signOut();
        return 'invalid';
      }
      // Auto-promote: if this is the designated admin email but Firestore role isn't admin yet
      if (signedInEmail == 'katefaithritcha@gmail.com' && role != 'admin') {
        try {
          await _db.collection('users').doc(uid).set({
            'email': signedInEmail,
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          role = 'admin';
        } catch (_) {}
      }

      // Upsert user document to ensure visibility in User Management and track activity
      try {
        await _db.collection('users').doc(uid).set({
          'email': signedInEmail,
          'role': role,
          'name': (cred.user?.displayName ?? (signedInEmail ?? '').split('@').first),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(), // merge keeps existing
        }, SetOptions(merge: true));
      } catch (_) {}

      return role;
    } catch (_) {
      return 'invalid';
    }
  }

  Future<String> registerUser(String email, String password, String role) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedRole = (role.trim().toLowerCase());

      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      final uid = cred.user?.uid;
      if (uid == null) return 'Registration failed';

      // Accept only health_worker or patient for general registrations.
      // Admin role is only allowed for the designated admin email.
      String finalRole;
      if (normalizedRole == 'health_worker') {
        finalRole = 'health_worker';
      } else if (normalizedRole == 'admin') {
        finalRole = normalizedEmail == 'katefaithritcha@gmail.com' ? 'admin' : 'patient';
      } else {
        finalRole = 'patient';
      }

      await _db.collection('users').doc(uid).set({
        'email': normalizedEmail,
        'role': finalRole,
        'name': (cred.user?.displayName ?? normalizedEmail.split('@').first),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return 'Registered successfully';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email already registered';
      return 'Registration failed';
    } catch (_) {
      return 'Registration failed';
    }
  }

  Future<String> _fetchUserRole(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data();
      final role = (data?['role'] as String?)?.trim();
      if (role == 'admin' || role == 'health_worker' || role == 'patient') {
        return role!;
      }
      return 'patient';
    } catch (_) {
      // If Firestore not available or doc missing, default to patient
      return 'patient';
    }
  }
}
