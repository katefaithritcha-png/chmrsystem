class Customer {
  final String id;
  final String firstname;
  final String lastname;
  final String address;

  Customer({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.address,
  });

  factory Customer.fromMap(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      firstname: data['firstname'] as String? ?? '',
      lastname: data['lastname'] as String? ?? '',
      address: data['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstname': firstname,
      'lastname': lastname,
      'address': address,
    };
  }

  String get fullName => '$firstname $lastname';
}
