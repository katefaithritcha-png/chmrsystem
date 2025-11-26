import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime? updatedAt;
  final String? notes;
  final bool isPwd;
  final bool isSeniorCitizen;
  final bool isPregnant;
  final bool isVoter;

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
    this.updatedAt,
    this.notes,
    this.isPwd = false,
    this.isSeniorCitizen = false,
    this.isPregnant = false,
    this.isVoter = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Resident.fromMap(String id, Map<String, dynamic> data) {
    return Resident(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      fullName: data['fullName'] ?? '',
      sex: data['sex'] ?? 'Unknown',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      civilStatus: data['civilStatus'],
      address: data['address'],
      purok: data['purok'],
      householdId: data['householdId'],
      contact: data['contact'],
      category: data['category'],
      status: data['status'] ?? 'Active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      isPwd: data['isPwd'] ?? false,
      isSeniorCitizen: data['isSeniorCitizen'] ?? false,
      isPregnant: data['isPregnant'] ?? false,
      isVoter: data['isVoter'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
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
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'notes': notes,
      'isPwd': isPwd,
      'isSeniorCitizen': isSeniorCitizen,
      'isPregnant': isPregnant,
      'isVoter': isVoter,
    };
  }

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
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isPwd,
    bool? isSeniorCitizen,
    bool? isPregnant,
    bool? isVoter,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isPwd: isPwd ?? this.isPwd,
      isSeniorCitizen: isSeniorCitizen ?? this.isSeniorCitizen,
      isPregnant: isPregnant ?? this.isPregnant,
      isVoter: isVoter ?? this.isVoter,
    );
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

  String get ageGroup {
    if (age <= 5) return '0-5';
    if (age <= 12) return '6-12';
    if (age <= 19) return '13-19';
    if (age <= 59) return '20-59';
    return '60+';
  }

  bool get isAdult => age >= 18;
  bool get isChild => age < 18;
  bool get isInfant => age < 1;
  bool get isToddler => age >= 1 && age <= 3;
  bool get isPreschooler => age >= 4 && age <= 5;
  bool get isSchoolAge => age >= 6 && age <= 12;
  bool get isTeenager => age >= 13 && age <= 19;
  bool get isYoungAdult => age >= 20 && age <= 39;
  bool get isMiddleAged => age >= 40 && age <= 59;
  bool get isSenior => age >= 60;
}
