class DashboardStats {
  final int totalUsers;
  final int activePatients;
  final int reportsGenerated;
  final int pendingApprovals;
  final double usersChange;
  final double patientsChange;
  final double reportsChange;
  final int pendingDelta;

  DashboardStats({
    required this.totalUsers,
    required this.activePatients,
    required this.reportsGenerated,
    required this.pendingApprovals,
    required this.usersChange,
    required this.patientsChange,
    required this.reportsChange,
    required this.pendingDelta,
  });
}

class ChartPoint {
  final int x;
  final double y1;
  final double y2;
  ChartPoint({required this.x, required this.y1, required this.y2});
}

class ActivityEntry {
  final String action;
  final String user;
  final DateTime time;
  ActivityEntry({required this.action, required this.user, required this.time});
}

class PatientSummary {
  final String id;
  final String name;
  final int age;
  final String sex;
  PatientSummary({required this.id, required this.name, required this.age, required this.sex});
}
