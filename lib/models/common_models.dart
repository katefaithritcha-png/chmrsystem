class AppUser {
  final String id;
  String name;
  String role; // admin, worker, patient
  String email;
  AppUser({required this.id, required this.name, required this.role, required this.email});
}

class PatientRecord {
  final String id;
  String name;
  int age;
  String sex;
  String diagnosis;
  PatientRecord({required this.id, required this.name, required this.age, required this.sex, required this.diagnosis});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'sex': sex,
        'diagnosis': diagnosis,
      };

  factory PatientRecord.fromJson(Map<String, dynamic> json) => PatientRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        age: (json['age'] as num).toInt(),
        sex: json['sex'] as String,
        diagnosis: json['diagnosis'] as String,
      );
}

class ReportSummary {
  final String id;
  final String title;
  final DateTime createdAt;
  final Map<String, num> metrics;
  ReportSummary({required this.id, required this.title, required this.createdAt, required this.metrics});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'metrics': metrics,
      };

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        metrics: (json['metrics'] as Map).map((k, v) => MapEntry(k.toString(), (v as num))),
      );
}

class AppNotification {
  final String id;
  final String message;
  bool read;
  final DateTime time;
  bool archived;
  AppNotification({required this.id, required this.message, required this.read, required this.time, this.archived = false});
}

class AuditEvent {
  final String id;
  final String actor;
  final String action;
  final String level; // info, warning, error
  final DateTime time;
  AuditEvent({required this.id, required this.actor, required this.action, required this.level, required this.time});
}

class BackupStatus {
  final DateTime? lastBackup;
  final bool inProgress;
  final double progress; // 0..1
  BackupStatus({required this.lastBackup, required this.inProgress, required this.progress});
}
