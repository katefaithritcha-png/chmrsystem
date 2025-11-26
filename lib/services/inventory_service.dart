import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockAlert {
  final String medicineId;
  final String medicineName;
  final int currentStock;
  final int threshold;
  final DateTime lastUpdated;

  StockAlert({
    required this.medicineId,
    required this.medicineName,
    required this.currentStock,
    required this.threshold,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory StockAlert.fromMap(Map<String, dynamic> map) {
    return StockAlert(
      medicineId: map['medicineId'] as String,
      medicineName: map['medicineName'] as String,
      currentStock: map['currentStock'] as int,
      threshold: map['threshold'] as int,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BatchInfo {
  final String id;
  final String medicineId;
  final String medicineName;
  final int quantity;
  final int qtyAvailable;
  final DateTime expiry;
  final DateTime receivedAt;
  final String? source;
  final String? location;

  BatchInfo({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.qtyAvailable,
    required this.expiry,
    required this.receivedAt,
    this.source,
    this.location,
  });

  factory BatchInfo.fromMap(String id, Map<String, dynamic> map) {
    return BatchInfo(
      id: id,
      medicineId: map['medicineId'] as String,
      medicineName: map['medicineName'] as String? ?? 'Unknown',
      quantity: map['quantity'] as int,
      qtyAvailable: map['qtyAvailable'] as int,
      expiry: (map['expiry'] as Timestamp).toDate(),
      receivedAt: (map['createdAt'] as Timestamp).toDate(),
      source: map['source'] as String?,
      location: map['location'] as String?,
    );
  }

  String get formattedExpiry => DateFormat('MMM d, y').format(expiry);
  String get status => expiry.isBefore(DateTime.now())
      ? 'Expired'
      : expiry.difference(DateTime.now()).inDays <= 30
          ? 'Expiring Soon'
          : 'Good';

  Color get statusColor {
    switch (status) {
      case 'Expired':
        return Colors.red;
      case 'Expiring Soon':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

class InventoryService {
  final FirebaseFirestore _db;
  static const int _lowStockThreshold = 20; // 20% of average monthly usage

  InventoryService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance {
    // Initialize any listeners or setup here
  }

  // Collections
  CollectionReference<Map<String, dynamic>> get medicines =>
      _db.collection('medicines');
  CollectionReference<Map<String, dynamic>> get batches =>
      _db.collection('medicine_batches');
  CollectionReference<Map<String, dynamic>> get movements =>
      _db.collection('stock_movements');
  CollectionReference<Map<String, dynamic>> get issues =>
      _db.collection('medicine_issues');
  CollectionReference<Map<String, dynamic>> get alerts =>
      _db.collection('stock_alerts');

  // Real-time stock level monitoring
  Stream<List<Map<String, dynamic>>> watchMedicines() {
    return medicines.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final currentStock = (data['currentStock'] as num).toInt();
        final monthlyUsage = (data['monthlyUsage'] as num).toInt();

        return <String, dynamic>{
          ...data,
          'id': doc.id,
          'stockLevel': _calculateStockLevel(currentStock, monthlyUsage),
        };
      }).toList();
    });
  }

  // Get low stock alerts
  Stream<List<StockAlert>> getStockAlerts() {
    return _db
        .collection('medicines')
        .where('currentStock', isLessThanOrEqualTo: _lowStockThreshold)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
            final threshold =
                (data['threshold'] as num?)?.toInt() ?? _lowStockThreshold;

            if (currentStock > threshold) return null;

            return StockAlert(
              medicineId: doc.id,
              medicineName: data['name'] as String? ?? 'Unknown',
              currentStock: currentStock,
              threshold: threshold,
              lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
            );
          })
          .whereType<StockAlert>()
          .toList();
    });
  }

  // Get expiring batches (within 30 days)
  Stream<List<BatchInfo>> getExpiringBatches() {
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
    return _db
        .collection('batches')
        .where('expiry',
            isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
        .where('qtyAvailable', isGreaterThan: 0)
        .orderBy('expiry', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final batchList = <BatchInfo>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final medicineId = data['medicineId'] as String;
        final medicineDoc =
            await _db.collection('medicines').doc(medicineId).get();
        final medicineData = medicineDoc.data();
        final medicineName = medicineData?['name'] as String? ?? 'Unknown';

        batchList.add(BatchInfo.fromMap(
          doc.id,
          {
            ...data,
            'medicineName': medicineName,
          },
        ));
      }
      return batchList;
    });
  }

  // Search medicines
  Stream<List<Map<String, dynamic>>> searchMedicines(String query) {
    if (query.isEmpty) {
      return watchMedicines();
    }

    final searchTerm = query.toLowerCase();
    return _db
        .collection('medicines')
        .orderBy('nameLower')
        .startAt([searchTerm])
        .endAt(['$searchTerm\uf8ff'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return <String, dynamic>{
              ...data,
              'id': doc.id,
              'stockLevel': _calculateStockLevel(
                (data['currentStock'] as num).toInt(),
                (data['monthlyUsage'] as num).toInt(),
              ),
            };
          }).toList();
        });
  }

  // Helper to calculate stock level status
  String _calculateStockLevel(int currentStock, int monthlyUsage) {
    if (monthlyUsage <= 0) return 'unknown';

    final monthsOfStock = currentStock / monthlyUsage;
    if (monthsOfStock <= 0.5) return 'critical';
    if (monthsOfStock <= 1) return 'low';
    if (monthsOfStock <= 3) return 'adequate';
    return 'high';
  }

  Future<String> registerMedicine({
    required String name,
    String? generic,
    String? dosage,
    String? category,
    String? notes,
    String? location,
  }) async {
    final doc = await medicines.add({
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'generic': generic?.trim(),
      'dosage': dosage?.trim(),
      'category': category?.trim(),
      'notes': notes?.trim(),
      'location': location?.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateMedicine({
    required String medicineId,
    String? name,
    String? generic,
    String? dosage,
    String? category,
    String? notes,
    String? location,
  }) async {
    final Map<String, dynamic> upd = {};
    if (name != null) {
      upd['name'] = name.trim();
      upd['nameLower'] = name.trim().toLowerCase();
    }
    if (generic != null) upd['generic'] = generic.trim();
    if (dosage != null) upd['dosage'] = dosage.trim();
    if (category != null) upd['category'] = category.trim();
    if (notes != null) upd['notes'] = notes.trim();
    if (location != null) upd['location'] = location.trim();
    if (upd.isEmpty) return;
    await medicines.doc(medicineId).update(upd);
  }

  Future<String> receiveStock({
    required String medicineId,
    required int quantity,
    required DateTime expiry,
    String? source,
  }) async {
    final batchDoc = await batches.add({
      'medicineId': medicineId,
      'quantity': quantity,
      'qtyAvailable': quantity,
      'expiry': Timestamp.fromDate(expiry),
      'source': source?.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await movements.add({
      'type': 'receive',
      'medicineId': medicineId,
      'batchId': batchDoc.id,
      'quantity': quantity,
      'at': FieldValue.serverTimestamp(),
      'source': source?.trim(),
    });
    return batchDoc.id;
  }

  // FEFO issuance: deduct from soonest-expiring batches first
  Future<void> issueToPatient({
    required String patientName,
    required String medicineId,
    required int quantity,
    String? purpose,
    String? staff,
    DateTime? issuedAt,
  }) async {
    final qs = await batches
        .where('medicineId', isEqualTo: medicineId)
        .where('qtyAvailable', isGreaterThan: 0)
        .orderBy('expiry')
        .limit(50)
        .get();

    var remaining = quantity;
    final write = _db.batch();

    for (final d in qs.docs) {
      if (remaining <= 0) break;
      final data = d.data();
      final avail = (data['qtyAvailable'] ?? 0) as int;
      if (avail <= 0) continue;
      final take = remaining <= avail ? remaining : avail;
      write.update(d.reference, {
        'qtyAvailable': avail - take,
      });
      remaining -= take;
      final mvRef = movements.doc();
      write.set(mvRef, {
        'type': 'issue',
        'medicineId': medicineId,
        'batchId': d.id,
        'quantity': take,
        'at': FieldValue.serverTimestamp(),
        'patientName': patientName,
        'purpose': purpose,
        'staff': staff,
      });
    }

    if (remaining > 0) {
      throw StateError('Insufficient stock to issue requested quantity');
    }

    final issueRef = issues.doc();
    write.set(issueRef, {
      'medicineId': medicineId,
      'quantity': quantity,
      'patientName': patientName,
      'purpose': purpose,
      'staff': staff,
      'issuedAt': issuedAt != null
          ? Timestamp.fromDate(issuedAt)
          : FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await write.commit();
  }

  // Lookup helpers
  Future<String?> findMedicineIdByExactName(String name) async {
    final q = name.trim().toLowerCase();
    if (q.isEmpty) return null;
    final snap =
        await medicines.where('nameLower', isEqualTo: q).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<List<Map<String, dynamic>>> suggestMedicines(String query,
      {int limit = 10}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final start = q;
    final end = '$q\uf8ff';
    final snap = await medicines
        .orderBy('nameLower')
        .startAt([start])
        .endAt([end])
        .limit(limit)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // Simple streams for KPIs (computed client-side)
  Stream<int> streamTotalMedicines() {
    return medicines.snapshots().map((s) => s.size);
  }

  // Sum of available quantities across all batches
  Stream<int> streamTotalUnits() {
    return batches.snapshots().map((s) => s.docs
        .fold<int>(0, (p, d) => p + ((d.data()['qtyAvailable'] ?? 0) as int)));
  }

  Stream<int> streamLowStockCount({int threshold = 20}) {
    // Count medicines whose total available units < threshold
    return batches.snapshots().map((s) {
      final Map<String, int> totals = {};
      for (final d in s.docs) {
        final mId = (d.data()['medicineId'] ?? '') as String;
        final avail = (d.data()['qtyAvailable'] ?? 0) as int;
        totals[mId] = (totals[mId] ?? 0) + avail;
      }
      return totals.values.where((v) => v > 0 && v < threshold).length;
    });
  }

  Stream<int> streamNearExpiryCount({int days = 30}) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return batches
        .where('expiry', isLessThan: Timestamp.fromDate(cutoff))
        .where('qtyAvailable', isGreaterThan: 0)
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> streamOutOfStockOrExpiredCount() {
    final today = DateTime.now();
    return batches.snapshots().map((s) {
      int count = 0;
      final Map<String, int> totals = {};
      for (final d in s.docs) {
        final data = d.data();
        final mId = (data['medicineId'] ?? '') as String;
        final avail = (data['qtyAvailable'] ?? 0) as int;
        totals[mId] = (totals[mId] ?? 0) + avail;
        final exp = data['expiry'];
        if (exp is Timestamp && exp.toDate().isBefore(today)) {
          count++; // batch expired
        }
      }
      // Count medicines out of stock
      final out = totals.values.where((v) => v <= 0).length;
      return count + out;
    });
  }

  // Detailed streams
  Stream<List<Map<String, dynamic>>> streamNearExpiryBatches(
      {int days = 30, int limit = 10}) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return batches
        .where('expiry', isLessThan: Timestamp.fromDate(cutoff))
        .where('qtyAvailable', isGreaterThan: 0)
        .orderBy('expiry')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final m = d.data();
              return {
                'batchId': d.id,
                'medicineId': m['medicineId'],
                'qtyAvailable': m['qtyAvailable'] ?? 0,
                'expiry': m['expiry'],
              };
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> streamLowStockMedicines(
      {int threshold = 20, int limit = 10}) {
    return batches.snapshots().map((s) {
      final Map<String, int> totals = {};
      for (final d in s.docs) {
        final data = d.data();
        final mId = (data['medicineId'] ?? '') as String;
        final avail = (data['qtyAvailable'] ?? 0) as int;
        totals[mId] = (totals[mId] ?? 0) + avail;
      }
      final items = totals.entries
          .where((e) => e.value > 0 && e.value < threshold)
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      return items
          .take(limit)
          .map((e) => {'medicineId': e.key, 'total': e.value})
          .toList();
    });
  }

  Future<String> getMedicineName(String id) async {
    final d = await medicines.doc(id).get();
    final m = d.data();
    if (m == null) return id;
    final name = (m['name'] ?? '').toString();
    return name.isEmpty ? id : name;
  }

  Future<Map<String, dynamic>?> getMedicine(String id) async {
    final d = await medicines.doc(id).get();
    return d.data();
  }

  Stream<List<Map<String, dynamic>>> streamMedicineSummaries() {
    return batches.snapshots().map((s) {
      final Map<String, int> totals = {};
      final Map<String, Timestamp?> minExp = {};
      for (final d in s.docs) {
        final data = d.data();
        final mId = (data['medicineId'] ?? '') as String;
        final avail = (data['qtyAvailable'] ?? 0) as int;
        totals[mId] = (totals[mId] ?? 0) + avail;
        final exp = data['expiry'];
        if (exp is Timestamp) {
          final cur = minExp[mId];
          if (cur == null || exp.toDate().isBefore(cur.toDate())) {
            minExp[mId] = exp;
          }
        }
      }
      return totals.entries
          .map((e) => {
                'medicineId': e.key,
                'total': e.value,
                'soonestExpiry': minExp[e.key],
              })
          .toList()
        ..sort((a, b) =>
            (a['medicineId'] as String).compareTo(b['medicineId'] as String));
    });
  }

  // Reports as CSV
  Future<String> inventorySummaryCsv() async {
    final summaries = await streamMedicineSummaries().first;
    const header = 'Medicine,Total,NextExpiry\n';
    final rows = await Future.wait(summaries.map((m) async {
      final name = await getMedicineName(m['medicineId'] as String);
      final total = m['total'] as int;
      final ts = m['soonestExpiry'];
      String exp = '';
      if (ts is Timestamp) exp = ts.toDate().toIso8601String().split('T').first;
      return '"$name",$total,$exp';
    }));
    return header + rows.join('\n');
  }

  Future<String> expiredBatchesCsv() async {
    final today = DateTime.now();
    final snap = await batches
        .where('expiry', isLessThan: Timestamp.fromDate(today))
        .where('qtyAvailable', isGreaterThan: 0)
        .orderBy('expiry')
        .limit(1000)
        .get();
    const header = 'Medicine,BatchId,Qty,Expiry\n';
    final rows = await Future.wait(snap.docs.map((d) async {
      final m = d.data();
      final name = await getMedicineName((m['medicineId'] ?? '') as String);
      final qty = (m['qtyAvailable'] ?? 0) as int;
      String exp = '';
      final ts = m['expiry'];
      if (ts is Timestamp) exp = ts.toDate().toIso8601String().split('T').first;
      return '"$name","${d.id}",$qty,$exp';
    }));
    return header + rows.join('\n');
  }

  Future<String> monthlyConsumptionCsv({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await movements
        .where('type', isEqualTo: 'issue')
        .where('at', isGreaterThan: Timestamp.fromDate(since))
        .limit(5000)
        .get();
    final Map<String, int> totals = {};
    for (final d in snap.docs) {
      final m = d.data();
      final id = (m['medicineId'] ?? '') as String;
      final q = (m['quantity'] ?? 0) as int;
      totals[id] = (totals[id] ?? 0) + q;
    }
    final header = 'Medicine,QuantityIssued(Last${days}d)\n';
    final rows = await Future.wait(totals.entries.map((e) async {
      final name = await getMedicineName(e.key);
      return '"$name",${e.value}';
    }));
    return header + rows.join('\n');
  }

  Future<String> restockCsv({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await movements
        .where('type', isEqualTo: 'receive')
        .where('at', isGreaterThan: Timestamp.fromDate(since))
        .limit(5000)
        .get();
    final Map<String, int> totals = {};
    for (final d in snap.docs) {
      final m = d.data();
      final id = (m['medicineId'] ?? '') as String;
      final q = (m['quantity'] ?? 0) as int;
      totals[id] = (totals[id] ?? 0) + q;
    }
    final header = 'Medicine,QuantityReceived(Last${days}d)\n';
    final rows = await Future.wait(totals.entries.map((e) async {
      final name = await getMedicineName(e.key);
      return '"$name",${e.value}';
    }));
    return header + rows.join('\n');
  }
}

extension InventoryDashHelpers on InventoryService {
  Stream<List<Map<String, dynamic>>> streamRecentReceives({int limit = 5}) {
    return movements
        .where('type', isEqualTo: 'receive')
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> streamUsageSeries(
      {int months = 6}) async* {
    final now = DateTime.now();
    final since = DateTime(now.year, now.month - months + 1, 1);
    await for (final s in movements
        .where('type', isEqualTo: 'issue')
        .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .snapshots()) {
      final Map<String, int> byMonth = {
        for (int i = 0; i < months; i++)
          _monthKey(DateTime(now.year, now.month - (months - 1 - i), 1)): 0
      };
      for (final d in s.docs) {
        final m = d.data();
        final ts = m['at'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          final key = _monthKey(DateTime(dt.year, dt.month, 1));
          byMonth[key] = (byMonth[key] ?? 0) + ((m['quantity'] ?? 0) as int);
        }
      }
      final List<Map<String, dynamic>> points = [];
      for (int i = 0; i < months; i++) {
        final dt = DateTime(now.year, now.month - (months - 1 - i), 1);
        final key = _monthKey(dt);
        points.add({'label': key, 'value': byMonth[key] ?? 0});
      }
      yield points;
    }
  }

  String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}
