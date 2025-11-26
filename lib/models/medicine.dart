import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dispense_record.dart';

class Medicine {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int initialQuantity;
  final int currentQuantity;
  final String unit;
  final DateTime expiryDate;
  final String supplier;
  final String? batchNumber;
  final String? storageConditions;
  final String? sideEffects;
  final String? dosage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DispenseRecord> dispenseHistory;
  final DateTime? lastRestocked;
  final DateTime? lastDispensed;

  int get quantity => currentQuantity; // For backward compatibility

  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required int quantity, // This will be the initial quantity
    required this.unit,
    required this.expiryDate,
    required this.supplier,
    this.batchNumber,
    this.storageConditions,
    this.sideEffects,
    this.dosage,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    int? initialQuantity,
    int? currentQuantity,
    List<DispenseRecord>? dispenseHistory,
    this.lastRestocked,
    this.lastDispensed,
  })  : initialQuantity = initialQuantity ?? quantity,
        currentQuantity = currentQuantity ?? quantity,
        dispenseHistory = dispenseHistory ?? [];

  // Record a dispense operation
  Medicine recordDispense(int quantity, String patientId, String notes) {
    if (quantity > currentQuantity) {
      throw Exception('Not enough stock available');
    }

    final newDispense = DispenseRecord(
      date: DateTime.now(),
      quantity: quantity,
      patientId: patientId,
      notes: notes,
    );

    return copyWith(
      currentQuantity: currentQuantity - quantity,
      dispenseHistory: [...dispenseHistory, newDispense],
      lastDispensed: DateTime.now(),
    );
  }

  // Record a restock operation
  Medicine recordRestock(int quantity, String batchNumber) {
    return copyWith(
      currentQuantity: currentQuantity + quantity,
      initialQuantity: initialQuantity + quantity,
      batchNumber: batchNumber,
      lastRestocked: DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Medicine copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    String? supplier,
    String? batchNumber,
    String? storageConditions,
    String? sideEffects,
    String? dosage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? initialQuantity,
    int? currentQuantity,
    List<DispenseRecord>? dispenseHistory,
    DateTime? lastRestocked,
    DateTime? lastDispensed,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.initialQuantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      supplier: supplier ?? this.supplier,
      batchNumber: batchNumber ?? this.batchNumber,
      storageConditions: storageConditions ?? this.storageConditions,
      sideEffects: sideEffects ?? this.sideEffects,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      initialQuantity: initialQuantity ?? this.initialQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      dispenseHistory: dispenseHistory ?? this.dispenseHistory,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      lastDispensed: lastDispensed ?? this.lastDispensed,
    );
  }

  Map<String, dynamic> toMap() {
    try {
      final map = {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'initialQuantity': initialQuantity,
        'currentQuantity': currentQuantity,
        'unit': unit,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'supplier': supplier,
        'batchNumber': batchNumber,
        'storageConditions': storageConditions,
        'sideEffects': sideEffects,
        'dosage': dosage,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'dispenseHistory': dispenseHistory.map((e) => e.toMap()).toList(),
        'lastRestocked':
            lastRestocked != null ? Timestamp.fromDate(lastRestocked!) : null,
        'lastDispensed':
            lastDispensed != null ? Timestamp.fromDate(lastDispensed!) : null,
      };

      if (kDebugMode) {
        print('Converted medicine to map: $map');
      }

      return map;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in toMap: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  factory Medicine.fromMap(String id, Map<String, dynamic> data) {
    try {
      if (kDebugMode) {
        print('Creating Medicine from map. ID: $id, Data: $data');
      }

      // Helper function to parse date from various formats
      DateTime? parseDate(dynamic dateData) {
        try {
          if (dateData == null) return null;
          if (dateData is Timestamp) return dateData.toDate();
          if (dateData is DateTime) return dateData;
          if (dateData is String) return DateTime.parse(dateData);
          return null;
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing date: $dateData, error: $e');
          }
          return null;
        }
      }

      final medicine = Medicine(
        id: id,
        name: data['name']?.toString() ?? 'Unnamed Medicine',
        description: data['description']?.toString() ?? '',
        category: data['category']?.toString() ?? 'Other',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (data['quantity'] as num?)?.toInt() ??
            0, // For backward compatibility
        unit: data['unit']?.toString() ?? 'pcs',
        expiryDate: parseDate(data['expiryDate']) ?? DateTime.now(),
        supplier: data['supplier']?.toString() ?? 'Unknown',
        batchNumber: data['batchNumber']?.toString(),
        storageConditions: data['storageConditions']?.toString(),
        sideEffects: data['sideEffects']?.toString(),
        dosage: data['dosage']?.toString(),
        notes: data['notes']?.toString(),
        createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
        updatedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
        initialQuantity: (data['initialQuantity'] as num?)?.toInt() ??
            (data['quantity'] as num?)?.toInt() ??
            0,
        currentQuantity: (data['currentQuantity'] as num?)?.toInt() ??
            (data['quantity'] as num?)?.toInt() ??
            0,
        dispenseHistory: (data['dispenseHistory'] as List<dynamic>?)
            ?.map((e) => DispenseRecord.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        lastRestocked: parseDate(data['lastRestocked']),
        lastDispensed: parseDate(data['lastDispensed']),
      );

      if (kDebugMode) {
        print('Created Medicine: ${medicine.toString()}');
      }

      return medicine;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in Medicine.fromMap: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}
