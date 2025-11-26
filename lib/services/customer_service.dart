import 'dart:async';

import '../models/customer.dart';

class CustomerService {
  final List<Customer> _customers = [];
  final StreamController<List<Customer>> _controller = StreamController<List<Customer>>.broadcast();

  Future<void> seedSampleIfEmpty() async {
    if (_customers.isEmpty) {
      _customers.addAll([
        Customer(id: 'C-1001', firstname: 'Jane', lastname: 'Doe', address: '123 Main St'),
        Customer(id: 'C-1002', firstname: 'John', lastname: 'Smith', address: '456 Oak Ave'),
      ]);
      // small delay to simulate IO
      await Future.delayed(const Duration(milliseconds: 50));
      _controller.add(List<Customer>.from(_customers));
    }
  }

  Stream<List<Customer>> customersStream() {
    // emit current state then stream updates
    Future.microtask(() => _controller.add(List<Customer>.from(_customers)));
    return _controller.stream;
  }

  Future<Customer> addCustomer(String firstname, String lastname, String address) async {
    final id = 'C-${1000 + _customers.length + 1}';
    final customer = Customer(id: id, firstname: firstname, lastname: lastname, address: address);
    _customers.add(customer);
    _controller.add(List<Customer>.from(_customers));
    return customer;
  }

  void dispose() {
    _controller.close();
  }
}
