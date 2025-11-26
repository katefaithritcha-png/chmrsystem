/// String utility extensions
extension StringExtensions on String {
  /// Check if string is empty or whitespace
  bool get isEmptyOrWhitespace => trim().isEmpty;

  /// Check if string is not empty
  bool get isNotEmptyOrWhitespace => !isEmptyOrWhitespace;

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number (basic)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,}$');
    return phoneRegex.hasMatch(this);
  }

  /// Truncate string to max length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Remove all whitespace
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Check if string contains only digits
  bool get isNumeric => RegExp(r'^[0-9]+$').hasMatch(this);

  /// Convert to title case
  String get toTitleCase {
    return split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
