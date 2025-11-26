import 'package:cloud_firestore/cloud_firestore.dart';

class DispenseRecord {
  final DateTime date;
  final int quantity;
  final String patientId;
  final String notes;

  DispenseRecord({
    required this.date,
    required this.quantity,
    required this.patientId,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'quantity': quantity,
      'patientId': patientId,
      'notes': notes,
    };
  }

  factory DispenseRecord.fromMap(Map<String, dynamic> map) {
    return DispenseRecord(
      date: (map['date'] as Timestamp).toDate(),
      quantity: map['quantity'] as int,
      patientId: map['patientId'] as String,
      notes: map['notes'] as String,
    );
  }
}
