/// Form validation utilities
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Password is required';
    }
    if (value!.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value,
      {String fieldName = 'This field'}) {
    if (value?.isEmpty ?? true) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,}$');
    if (!phoneRegex.hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength) {
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    if (value!.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength) {
    if ((value?.length ?? 0) > maxLength) {
      return 'Must not exceed $maxLength characters';
    }
    return null;
  }

  /// Validate numeric value
  static String? validateNumeric(String? value) {
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value!)) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value?.isEmpty ?? true) {
      return 'URL is required';
    }
    try {
      Uri.parse(value!);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Validate date format (YYYY-MM-DD)
  static String? validateDate(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Date is required';
    }
    try {
      DateTime.parse(value!);
      return null;
    } catch (e) {
      return 'Please enter a valid date (YYYY-MM-DD)';
    }
  }

  /// Validate passwords match
  static String? validatePasswordsMatch(
      String? value, String? confirmPassword) {
    if (value != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
