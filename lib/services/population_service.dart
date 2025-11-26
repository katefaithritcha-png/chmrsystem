import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PopulationStats {
  final int totalResidents;
  final int totalHouseholds;
  final Map<String, int> ageGroups;
  final Map<String, int> genderCounts;
  final Map<String, int> purokCounts;
  final Map<String, int> statusCounts;

  PopulationStats({
    required this.totalResidents,
    required this.totalHouseholds,
    required this.ageGroups,
    required this.genderCounts,
    required this.purokCounts,
    required this.statusCounts,
  });

  factory PopulationStats.initial() {
    return PopulationStats(
      totalResidents: 0,
      totalHouseholds: 0,
      ageGroups: {'0-5': 0, '6-12': 0, '13-19': 0, '20-59': 0, '60+': 0},
      genderCounts: {'male': 0, 'female': 0, 'other': 0},
      purokCounts: {},
      statusCounts: {},
    );
  }
}

class Resident {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String sex;
  final DateTime birthDate;
  final String? civilStatus;
  final String? address;
  final String? purok;
  final String? householdId;
  final String? contact;
  final String? category;
  final String status;
  final DateTime createdAt;

  Resident copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? fullName,
    String? sex,
    DateTime? birthDate,
    String? civilStatus,
    String? address,
    String? purok,
    String? householdId,
    String? contact,
    String? category,
    String? status,
  }) {
    return Resident(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      civilStatus: civilStatus ?? this.civilStatus,
      address: address ?? this.address,
      purok: purok ?? this.purok,
      householdId: householdId ?? this.householdId,
      contact: contact ?? this.contact,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  Resident({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.sex,
    required this.birthDate,
    this.civilStatus,
    this.address,
    this.purok,
    this.householdId,
    this.contact,
    this.category,
    this.status = 'Active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Resident.fromMap(String id, Map<String, dynamic> data) {
    return Resident(
      id: id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      sex: data['sex'] as String? ?? 'other',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      civilStatus: data['civilStatus'] as String?,
      address: data['address'] as String?,
      purok: data['purok'] as String?,
      householdId: data['householdId'] as String?,
      contact: data['contact'] as String?,
      category: data['category'] as String?,
      status: data['status'] as String? ?? 'Active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'fullNameLower': fullName.toLowerCase(),
      'sex': sex,
      'birthDate': Timestamp.fromDate(birthDate),
      'civilStatus': civilStatus,
      'address': address,
      'purok': purok,
      'householdId': householdId,
      'contact': contact,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String get formattedBirthDate => DateFormat('MMM d, y').format(birthDate);
  String get ageGroup {
    if (age <= 5) return '0-5';
    if (age <= 12) return '6-12';
    if (age <= 19) return '13-19';
    if (age <= 59) return '20-59';
    return '60+';
  }
}

class PopulationService {
  final FirebaseFirestore _db;

  PopulationService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance {
    // Initialize any listeners or setup here
  }

  // Collections
  CollectionReference<Map<String, dynamic>> get residents =>
      _db.collection('residents');
  CollectionReference<Map<String, dynamic>> get households =>
      _db.collection('households');
  CollectionReference<Map<String, dynamic>> get movements =>
      _db.collection('population_movements');

  // Real-time population statistics
  Stream<PopulationStats> watchPopulationStats() {
    return residents.snapshots().asyncMap((snapshot) async {
      final stats = PopulationStats.initial();
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final birthDate = (data['birthDate'] as Timestamp?)?.toDate();

        if (birthDate != null) {
          final age = now.year -
              birthDate.year -
              (now.month < birthDate.month ||
                      (now.month == birthDate.month && now.day < birthDate.day)
                  ? 1
                  : 0);

          // Update age groups
          if (age <= 5) {
            stats.ageGroups['0-5'] = (stats.ageGroups['0-5'] ?? 0) + 1;
          } else if (age <= 12) {
            stats.ageGroups['6-12'] = (stats.ageGroups['6-12'] ?? 0) + 1;
          } else if (age <= 19) {
            stats.ageGroups['13-19'] = (stats.ageGroups['13-19'] ?? 0) + 1;
          } else if (age <= 59) {
            stats.ageGroups['20-59'] = (stats.ageGroups['20-59'] ?? 0) + 1;
          } else {
            stats.ageGroups['60+'] = (stats.ageGroups['60+'] ?? 0) + 1;
          }
        }

        // Update gender counts
        final gender = (data['sex'] as String?)?.toLowerCase() ?? 'other';
        if (gender.startsWith('m')) {
          stats.genderCounts['male'] = (stats.genderCounts['male'] ?? 0) + 1;
        } else if (gender.startsWith('f')) {
          stats.genderCounts['female'] =
              (stats.genderCounts['female'] ?? 0) + 1;
        } else {
          stats.genderCounts['other'] = (stats.genderCounts['other'] ?? 0) + 1;
        }

        // Update purok counts
        final purok = data['purok'] as String?;
        if (purok != null) {
          stats.purokCounts[purok] = (stats.purokCounts[purok] ?? 0) + 1;
        }

        // Update status counts
        final status = (data['status'] as String?) ?? 'Active';
        stats.statusCounts[status] = (stats.statusCounts[status] ?? 0) + 1;
      }

      // Get household count
      final householdCount = await households.count().get();

      return PopulationStats(
        totalResidents: snapshot.size,
        totalHouseholds: householdCount.count ?? 0,
        ageGroups: stats.ageGroups,
        genderCounts: stats.genderCounts,
        purokCounts: stats.purokCounts,
        statusCounts: stats.statusCounts,
      );
    });
  }

  // Search residents with filters
  Stream<List<Resident>> searchResidents({
    String? query,
    String? purok,
    String? ageGroup,
    String? gender,
    String? status,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> queryRef = residents;

    if (query != null && query.isNotEmpty) {
      final searchTerm = query.toLowerCase();
      queryRef = queryRef
          .orderBy('fullNameLower')
          .startAt([searchTerm]).endAt(['$searchTerm\uf8ff']);
    }

    if (purok != null && purok.isNotEmpty) {
      queryRef = queryRef.where('purok', isEqualTo: purok);
    }

    if (gender != null && gender.isNotEmpty) {
      queryRef = queryRef.where('sex', isEqualTo: gender);
    }

    if (status != null && status.isNotEmpty) {
      queryRef = queryRef.where('status', isEqualTo: status);
    }

    return queryRef.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Resident.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get resident by ID
  Future<Resident?> getResident(String id) async {
    final doc = await residents.doc(id).get();
    if (!doc.exists) return null;
    return Resident.fromMap(doc.id, doc.data()!);
  }

  // Get residents by household
  Stream<List<Resident>> getHouseholdMembers(String householdId) {
    return residents
        .where('householdId', isEqualTo: householdId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resident.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get residents by purok
  Stream<List<Resident>> getResidentsByPurok(String purok) {
    return residents.where('purok', isEqualTo: purok).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Resident.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Create/update
  // Add or update a resident
  Future<String> saveResident(Resident resident) async {
    final data = resident.toMap();

    if (resident.id.isEmpty) {
      // Add new resident
      final doc = await residents.add(data);
      return doc.id;
    } else {
      // Update existing resident
      await residents.doc(resident.id).update(data);
      return resident.id;
    }
  }

  // Delete a resident
  Future<void> deleteResident(String id) async {
    await residents.doc(id).delete();
  }

  // Get all puroks
  Stream<List<String>> getPuroks() {
    return residents.snapshots().map((snapshot) {
      final puroks = <String>{};
      for (final doc in snapshot.docs) {
        final purok = doc.data()['purok'] as String?;
        if (purok != null && purok.isNotEmpty) {
          puroks.add(purok);
        }
      }
      return puroks.toList()..sort();
    });
  }

  // Get all categories
  Stream<List<String>> getCategories() {
    return residents.snapshots().map((snapshot) {
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      return categories.toList()..sort();
    });
  }

  // Import residents from CSV
  Future<int> importFromCsv(List<Map<String, dynamic>> rows) async {
    int count = 0;
    final batch = _db.batch();

    for (final row in rows) {
      try {
        final resident = Resident(
          id: '', // New document
          firstName: row['firstName']?.toString().trim() ?? '',
          lastName: row['lastName']?.toString().trim() ?? '',
          fullName: '${row['firstName']} ${row['lastName']}'.trim(),
          sex: (row['sex']?.toString().toLowerCase() ?? '').startsWith('f')
              ? 'Female'
              : 'Male',
          birthDate: _parseDate(row['birthDate']),
          civilStatus: row['civilStatus']?.toString(),
          address: row['address']?.toString(),
          purok: row['purok']?.toString(),
          contact: row['contact']?.toString(),
          category: row['category']?.toString(),
          status: row['status']?.toString() ?? 'Active',
        );

        final data = resident.toMap();
        final docRef = residents.doc(); // Auto-generated ID
        batch.set(docRef, data);
        count++;

        // Commit in batches of 100
        if (count % 100 == 0) {
          await batch.commit();
        }
      } catch (_) {}
    }

    // Commit any remaining operations
    if (count % 100 != 0) {
      await batch.commit();
    }

    return count;
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    if (dateValue is DateTime) return dateValue;
    if (dateValue is Timestamp) return dateValue.toDate();

    final str = dateValue.toString();
    if (str.isEmpty) return DateTime.now();

    // Try parsing common date formats
    try {
      return DateTime.parse(str);
    } catch (_) {
      try {
        final parts = str.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    return DateTime.now();
  }

  // Monthly population trend: count residents by createdAt month (last 12 months)
  Stream<List<Map<String, dynamic>>> streamPopulationTrend(
      {int months = 12}) async* {
    final now = DateTime.now();
    final since = DateTime(now.year, now.month - months + 1, 1);
    await for (final snap in residents
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .snapshots()) {
      final Map<String, int> byMonth = {
        for (int i = 0; i < months; i++)
          _monthKey(DateTime(now.year, now.month - (months - 1 - i), 1)): 0
      };
      for (final d in snap.docs) {
        final ts = d.data()['createdAt'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          final key = _monthKey(DateTime(dt.year, dt.month, 1));
          byMonth[key] = (byMonth[key] ?? 0) + 1;
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

  // Household stats
  Stream<Map<String, num>> streamHouseholdStats() {
    return households.snapshots().map((s) {
      final total = s.size;
      int members = 0;
      for (final d in s.docs) {
        members += (d.data()['members'] ?? 0) as int;
      }
      final avg = total == 0 ? 0 : members / total;
      return {'households': total, 'avgMembers': avg};
    });
  }

  // Counts by purok
  Stream<List<Map<String, dynamic>>> streamCountsByPurok() {
    return residents.snapshots().map((s) {
      final Map<String, int> byPurok = {};
      for (final d in s.docs) {
        final p = (d.data()['purok'] ?? 'Unknown').toString();
        byPurok[p] = (byPurok[p] ?? 0) + 1;
      }
      final items = byPurok.entries
          .map((e) => {'purok': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      return items;
    });
  }

  // Monthly changes summary for current month
  Stream<Map<String, int>> streamMonthlyChanges() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return movements
        .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .snapshots()
        .map((s) {
      int newRes = 0, moved = 0, deceased = 0;
      for (final d in s.docs) {
        final st = (d.data()['status'] ?? '').toString().toLowerCase();
        if (st.contains('moved')) {
          moved++;
        } else if (st.contains('deceased')) {
          deceased++;
        } else {
          newRes++;
        }
      }
      return {'new': newRes, 'moved': moved, 'deceased': deceased};
    });
  }

  Future<String> addHousehold({
    required String address,
    String? purok,
    String? headName,
    int members = 0,
  }) async {
    final doc = await households.add({
      'address': address,
      'purok': purok,
      'headName': headName,
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateResidentStatus(String residentId, String status,
      {String? note}) async {
    await residents.doc(residentId).update({'status': status});
    await movements.add({
      'residentId': residentId,
      'status': status,
      'note': note,
      'at': FieldValue.serverTimestamp(),
    });
  }

  // Streams for dashboard KPIs
  Stream<int> streamTotalResidents() =>
      residents.snapshots().map((s) => s.size);
  Stream<int> streamTotalHouseholds() =>
      households.snapshots().map((s) => s.size);
  Stream<int> streamSeniors() {
    final today = DateTime.now();
    final cutoff = DateTime(today.year - 60, today.month, today.day);
    return residents
        .where('birthDate', isLessThan: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> streamPWDs() => residents
      .where('category', isEqualTo: 'PWD')
      .snapshots()
      .map((s) => s.size);
  Stream<int> streamChildren05() {
    final today = DateTime.now();
    final cutoff = DateTime(today.year - 5, today.month, today.day);
    return residents
        .where('birthDate', isGreaterThan: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((s) => s.size);
  }

  // Lists
  Stream<List<Map<String, dynamic>>> streamRecentMovements({int limit = 10}) {
    return movements
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> streamMovementsForResident(
      String residentId,
      {int limit = 20}) {
    return movements
        .where('residentId', isEqualTo: residentId)
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> streamResidents(
      {String? query, String? purok, String? status}) {
    Query<Map<String, dynamic>> q = residents;
    if (status != null && status.isNotEmpty) {
      q = q.where('status', isEqualTo: status);
    }
    // For simplicity, client-side filter for name & purok
    return q
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).where((m) {
              final okName = query == null ||
                  query.isEmpty ||
                  (m['fullNameLower'] ?? '')
                      .toString()
                      .contains(query.toLowerCase());
              final okPurok =
                  purok == null || purok.isEmpty || (m['purok'] ?? '') == purok;
              return okName && okPurok;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> streamHouseholds({String? purok}) {
    Query<Map<String, dynamic>> query = _db.collection('households');
    if (purok != null && purok.isNotEmpty) {
      query = query.where('purok', isEqualTo: purok);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .toList());
  }

  Stream<List<Map<String, dynamic>>> searchHouseholds({
    String? query,
    String? purok,
  }) {
    Query<Map<String, dynamic>> queryRef = _db.collection('households');

    if (purok != null && purok.isNotEmpty) {
      queryRef = queryRef.where('purok', isEqualTo: purok);
    }

    if (query != null && query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      return queryRef.snapshots().map((snapshot) {
        return snapshot.docs.where((doc) {
          final data = doc.data();
          final address = (data['address'] as String? ?? '').toLowerCase();
          final headName = (data['headName'] as String? ?? '').toLowerCase();
          return address.contains(searchQuery) ||
              headName.contains(searchQuery);
        }).map((doc) {
          final data = doc.data();
          return <String, dynamic>{
            'id': doc.id,
            ...data,
            'memberCount': (data['memberCount'] as int?) ?? 0,
          };
        }).toList();
      });
    }

    return queryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          ...data,
          'memberCount': (data['memberCount'] as int?) ?? 0,
        };
      }).toList();
    });
  }
}

String _monthKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

// CSV exports
extension PopulationCsv on PopulationService {
  Future<String> seniorsCsv() async {
    final today = DateTime.now();
    final cutoff = DateTime(today.year - 60, today.month, today.day);
    final snap = await residents
        .where('birthDate', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    const header = 'FullName,Sex,BirthDate,Purok,Address,Status\n';
    final rows = snap.docs.map((d) {
      final m = d.data();
      final ts = m['birthDate'];
      String dob = '';
      if (ts is Timestamp) dob = ts.toDate().toIso8601String().split('T').first;
      return '"${m['fullName'] ?? ''}",${m['sex'] ?? ''},$dob,${m['purok'] ?? ''},"${m['address'] ?? ''}",${m['status'] ?? ''}';
    }).join('\n');
    return header + rows;
  }

  Future<String> pwdCsv() async {
    final snap = await residents.where('category', isEqualTo: 'PWD').get();
    const header = 'FullName,Sex,BirthDate,Purok,Address,Status\n';
    final rows = snap.docs.map((d) {
      final m = d.data();
      final ts = m['birthDate'];
      String dob = '';
      if (ts is Timestamp) dob = ts.toDate().toIso8601String().split('T').first;
      return '"${m['fullName'] ?? ''}",${m['sex'] ?? ''},$dob,${m['purok'] ?? ''},"${m['address'] ?? ''}",${m['status'] ?? ''}';
    }).join('\n');
    return header + rows;
  }

  Future<String> pregnantCsv() async {
    // Using substring match on category; adjust as needed per your stored values
    final snap = await residents.get();
    final items = snap.docs.where((d) =>
        (d.data()['category'] ?? '').toString().toLowerCase().contains('preg'));
    const header = 'FullName,Sex,BirthDate,Purok,Address,Status\n';
    final rows = items.map((d) {
      final m = d.data();
      final ts = m['birthDate'];
      String dob = '';
      if (ts is Timestamp) dob = ts.toDate().toIso8601String().split('T').first;
      return '"${m['fullName'] ?? ''}",${m['sex'] ?? ''},$dob,${m['purok'] ?? ''},"${m['address'] ?? ''}",${m['status'] ?? ''}';
    }).join('\n');
    return header + rows;
  }

  Future<String> householdSummaryCsv() async {
    final snap = await households.get();
    const header = 'HouseholdId,Address,Purok,HeadName,Members\n';
    final rows = snap.docs.map((d) {
      final m = d.data();
      return '"${d.id}","${m['address'] ?? ''}",${m['purok'] ?? ''},"${m['headName'] ?? ''}",${m['members'] ?? 0}';
    }).join('\n');
    return header + rows;
  }
}
