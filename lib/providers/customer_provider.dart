import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _service = CustomerService();
  StreamSubscription<List<Customer>>? _sub;

  List<Customer> _customers = [];
  bool _loading = true;
  Object? _error;

  CustomerProvider() {
    _init();
  }

  List<Customer> get customers => _customers;
  bool get isLoading => _loading;
  Object? get error => _error;

  Future<void> _init() async {
    try {
      await _service.seedSampleIfEmpty();
      _sub = _service.customersStream().listen((data) {
        _customers = data;
        _loading = false;
        _error = null;
        notifyListeners();
      }, onError: (e) {
        _error = e;
        _loading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
