import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentResult {
  AppointmentResult({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.workerId,
    required this.dateTime,
    this.bp,
    this.temperature,
    this.pulse,
    this.respiratoryRate,
    this.weight,
    this.height,
    this.spo2,
    this.symptoms,
    this.clinicalFindings,
    this.diagnosis,
    this.notes,
    this.medications,
    this.dosage,
    this.instructions,
    this.followUpDate,
    this.referral,
    this.labResults = const [],
    this.prescriptions = const [],
    this.images = const [],
  });

  final String appointmentId;
  final String patientId;
  final String patientName;
  final String workerId;
  final String dateTime;

  final String? bp;
  final double? temperature;
  final int? pulse;
  final int? respiratoryRate;
  final double? weight;
  final double? height;
  final int? spo2;

  final String? symptoms;
  final String? clinicalFindings;
  final String? diagnosis;
  final String? notes;

  final String? medications;
  final String? dosage;
  final String? instructions;
  final String? followUpDate;
  final String? referral;

  final List<String> labResults;
  final List<String> prescriptions;
  final List<String> images;

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'workerId': workerId,
      'dateTime': dateTime,
      'vitalSigns': {
        'bp': bp,
        'temperature': temperature,
        'pulse': pulse,
        'respiratoryRate': respiratoryRate,
        'weight': weight,
        'height': height,
        'spo2': spo2,
      },
      'caseInfo': {
        'symptoms': symptoms,
        'clinicalFindings': clinicalFindings,
        'diagnosis': diagnosis,
        'notes': notes,
      },
      'treatment': {
        'medications': medications,
        'dosage': dosage,
        'instructions': instructions,
        'followUpDate': followUpDate,
        'referral': referral,
      },
      'uploads': {
        'labResults': labResults,
        'prescriptions': prescriptions,
        'images': images,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static AppointmentResult fromMap(Map<String, dynamic> m) {
    final vitals = (m['vitalSigns'] ?? {}) as Map<String, dynamic>;
    final caseInfo = (m['caseInfo'] ?? {}) as Map<String, dynamic>;
    final treatment = (m['treatment'] ?? {}) as Map<String, dynamic>;
    final uploads = (m['uploads'] ?? {}) as Map<String, dynamic>;

    return AppointmentResult(
      appointmentId: m['appointmentId'] as String,
      patientId: m['patientId'] as String,
      patientName: m['patientName'] as String,
      workerId: m['workerId'] as String,
      dateTime: m['dateTime'] as String,
      bp: vitals['bp'] as String?,
      temperature: (vitals['temperature'] as num?)?.toDouble(),
      pulse: (vitals['pulse'] as num?)?.toInt(),
      respiratoryRate: (vitals['respiratoryRate'] as num?)?.toInt(),
      weight: (vitals['weight'] as num?)?.toDouble(),
      height: (vitals['height'] as num?)?.toDouble(),
      spo2: (vitals['spo2'] as num?)?.toInt(),
      symptoms: caseInfo['symptoms'] as String?,
      clinicalFindings: caseInfo['clinicalFindings'] as String?,
      diagnosis: caseInfo['diagnosis'] as String?,
      notes: caseInfo['notes'] as String?,
      medications: treatment['medications'] as String?,
      dosage: treatment['dosage'] as String?,
      instructions: treatment['instructions'] as String?,
      followUpDate: treatment['followUpDate'] as String?,
      referral: treatment['referral'] as String?,
      labResults: List<String>.from(
          (uploads['labResults'] ?? const <String>[]) as List),
      prescriptions: List<String>.from(
          (uploads['prescriptions'] ?? const <String>[]) as List),
      images:
          List<String>.from((uploads['images'] ?? const <String>[]) as List),
    );
  }
}

class AppointmentResultsService {
  AppointmentResultsService._();
  static final instance = AppointmentResultsService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointment_results');

  Future<AppointmentResult?> getByAppointmentId(String appointmentId) async {
    final doc = await _col.doc(appointmentId).get();
    if (!doc.exists) return null;
    return AppointmentResult.fromMap(doc.data()!);
  }

  Future<void> saveForAppointment(AppointmentResult result) async {
    await _col.doc(result.appointmentId).set(
          result.toMap(),
          SetOptions(merge: true),
        );

    // Mark appointment as completed
    await _db
        .collection('appointments')
        .doc(result.appointmentId)
        .set({'status': 'completed'}, SetOptions(merge: true));

    // Create patient health history entry
    await _db.collection('patient_health_records').add({
      'patientId': result.patientId,
      'appointmentId': result.appointmentId,
      'type': 'checkup',
      'date': result.dateTime,
      'summary': result.diagnosis ?? 'Check-up completed',
      'resultRef': _col.doc(result.appointmentId).path,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Optionally: a higher-level service can create notifications/audit logs.
  }
}
