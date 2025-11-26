import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chmrsystem/models/medicine.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'medicines';

  // Add a new medicine
  Future<Medicine> addMedicine(Medicine medicine) async {
    try {
      if (kDebugMode) {
        print('Adding medicine: ${medicine.name}');
      }

      final now = DateTime.now();
      final medicineData = medicine.toMap()
        ..addAll({
          'createdAt': now,
          'updatedAt': now,
        });

      if (kDebugMode) {
        print('Medicine data to save: $medicineData');
      }

      final docRef =
          await _firestore.collection(_collectionName).add(medicineData);

      if (kDebugMode) {
        print('Medicine added with ID: ${docRef.id}');
      }

      return medicine.copyWith(
        id: docRef.id,
        createdAt: now,
        updatedAt: now,
      );
    } on FirebaseException catch (e) {
      final errorMsg = 'Firebase error (${e.code}): ${e.message}';
      if (kDebugMode) {
        print(errorMsg);
      }
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error adding medicine: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Failed to add medicine: $e');
    }
  }

  // Update an existing medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      if (kDebugMode) {
        print('Updating medicine ID: ${medicine.id}');
      }

      final now = DateTime.now();
      final updateData = medicine.toMap()
        ..remove('createdAt') // Don't update created date
        ..update('updatedAt', (_) => now);

      if (kDebugMode) {
        print('Update data: $updateData');
      }

      await _firestore
          .collection(_collectionName)
          .doc(medicine.id)
          .update(updateData);

      if (kDebugMode) {
        print('Medicine updated successfully');
      }
    } on FirebaseException catch (e) {
      final errorMsg = 'Firebase error (${e.code}): ${e.message}';
      if (kDebugMode) {
        print(errorMsg);
      }
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error updating medicine: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Failed to update medicine: $e');
    }
  }

  // Delete a medicine
  Future<void> deleteMedicine(String medicineId) async {
    try {
      await _firestore.collection(_collectionName).doc(medicineId).delete();
    } catch (e) {
      throw Exception('Failed to delete medicine: $e');
    }
  }

  // Get a single medicine by ID
  Future<Medicine?> getMedicine(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return Medicine.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get medicine: $e');
    }
  }

  // Stream all medicines
  Stream<List<Medicine>> getMedicines() {
    return _firestore
        .collection(_collectionName)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicine.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get medicines by category
  Stream<List<Medicine>> getMedicinesByCategory(String category) {
    return _firestore
        .collection(_collectionName)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicine.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update medicine quantity (for stock management)
  Future<void> updateStock(String medicineId, int quantityChange) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(_collectionName).doc(medicineId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Medicine not found');
        }

        final currentQuantity = doc['quantity'] as int;
        final newQuantity = currentQuantity + quantityChange;

        if (newQuantity < 0) {
          throw Exception('Insufficient stock');
        }

        transaction.update(docRef, {
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Get low stock medicines (below threshold)
  Stream<List<Medicine>> getLowStockMedicines({int threshold = 10}) {
    return _firestore
        .collection(_collectionName)
        .where('quantity', isLessThan: threshold)
        .orderBy('quantity')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicine.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get expired or soon-to-expire medicines
  Stream<List<Medicine>> getExpiringMedicines({int days = 30}) {
    final expiryDate = DateTime.now().add(Duration(days: days));
    return _firestore
        .collection(_collectionName)
        .where('expiryDate', isLessThanOrEqualTo: expiryDate)
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicine.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update medicine quantity
  Future<void> updateMedicineQuantity(
      String medicineId, int quantityChange) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(_collectionName).doc(medicineId);
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('Medicine not found');
        }

        final currentQuantity = doc.get('quantity') as int;
        final newQuantity = currentQuantity + quantityChange;

        if (newQuantity < 0) {
          throw Exception('Insufficient stock');
        }

        transaction.update(docRef, {
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to update medicine quantity: $e');
    }
  }

  // Add transaction
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      await _firestore.collection('medicine_transactions').add({
        ...transactionData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Search medicines by name
  Stream<List<Medicine>> searchMedicines(String query) {
    if (query.isEmpty) {
      return getMedicines();
    }

    return _firestore
        .collection(_collectionName)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicine.fromMap(doc.id, doc.data()))
            .toList());
  }
}
