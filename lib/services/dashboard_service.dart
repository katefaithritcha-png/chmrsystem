import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DashboardStats> fetchStats() async {
    // Basic counts for dashboard KPIs
    final usersF = _db.collection('users').get();
    final patientsF = _db.collection('patients').get();
    final pendingF = _db
        .collection('appointments')
        .where('status', isEqualTo: 'pending')
        .get();
    // Optional: count report exports via audit actions starting with 'reports.'
    final reportsF = _db
        .collection('audit')
        .where('action', whereIn: ['reports.export.csv', 'reports.export.pdf'])
        .limit(500)
        .get();

    final res = await Future.wait([usersF, patientsF, pendingF, reportsF]);
    final users = res[0] as QuerySnapshot;
    final patients = res[1] as QuerySnapshot;
    final pending = res[2] as QuerySnapshot;
    final reports = res[3] as QuerySnapshot;

    return DashboardStats(
      totalUsers: users.size,
      activePatients: patients.size,
      reportsGenerated: reports.size,
      pendingApprovals: pending.size,
      // Deltas not tracked yet; set to 0
      usersChange: 0.0,
      patientsChange: 0.0,
      reportsChange: 0.0,
      pendingDelta: 0,
    );
  }

  Future<List<ChartPoint>> fetchPatientChart() async {
    // Simple last 6 periods using counts: patients and consultations completed
    final now = DateTime.now();
    final List<ChartPoint> points = [];
    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);
      final patientsQ = await _db
          .collection('patients')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(monthEnd))
          .get();
      final consultsQ = await _db
          .collection('consultations')
          .where('endedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('endedAt', isLessThan: Timestamp.fromDate(monthEnd))
          .get();
      points.add(ChartPoint(x: monthStart.month, y1: patientsQ.size.toDouble(), y2: consultsQ.size.toDouble()));
    }
    return points;
  }

  Future<List<ActivityEntry>> fetchRecentActivity() async {
    final snap = await _db
        .collection('audit')
        .orderBy('at', descending: true)
        .limit(8)
        .get();
    return snap.docs.map((d) {
      final m = d.data();
      final ts = m['at'];
      final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
      return ActivityEntry(
        action: (m['action'] ?? '').toString(),
        user: '${m['actorRole'] ?? ''}:${m['actorId'] ?? ''}',
        time: dt,
      );
    }).toList();
  }

  Future<List<PatientSummary>> searchPatients(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <PatientSummary>[];
    // Prefix search on 'name' using range query
    final start = q;
    final end = '$q\uf8ff';
    final snap = await _db
        .collection('patients')
        .orderBy('nameLower', descending: false)
        .startAt([start])
        .endAt([end])
        .limit(20)
        .get();
    if (snap.size == 0) {
      // fallback: naive scan limited
      final all = await _db.collection('patients').limit(50).get();
      return all.docs
          .map((d) => d.data())
          .whereType<Map<String, dynamic>>()
          .where((m) => (m['name'] ?? '').toString().toLowerCase().contains(q))
          .map((m) => PatientSummary(
                id: (m['id'] ?? '').toString(),
                name: (m['name'] ?? '').toString(),
                age: (m['age'] ?? 0) as int,
                sex: (m['sex'] ?? '').toString(),
              ))
          .toList();
    }
    return snap.docs.map((d) {
      final m = d.data();
      return PatientSummary(
        id: d.id,
        name: (m['name'] ?? '').toString(),
        age: (m['age'] ?? 0) as int,
        sex: (m['sex'] ?? '').toString(),
      );
    }).toList();
  }
}
