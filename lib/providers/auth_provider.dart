import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  String? _role; // 'admin', 'health_worker', 'patient'

  String? get role => _role;
  bool get isLoggedIn => _role != null;

  void setRole(String? role) {
    _role = role;
    notifyListeners();
  }

  void logout() {
    _role = null;
    notifyListeners();
  }
}
