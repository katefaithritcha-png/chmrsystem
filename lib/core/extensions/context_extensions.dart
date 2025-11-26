import 'package:flutter/material.dart';

/// BuildContext utility extensions
extension ContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if device is in landscape
  bool get isLandscape => screenWidth > screenHeight;

  /// Check if device is in portrait
  bool get isPortrait => screenWidth <= screenHeight;

  /// Check if device is mobile (width < 600)
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet (width >= 600 && width < 1200)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Check if device is desktop (width >= 1200)
  bool get isDesktop => screenWidth >= 1200;

  /// Get device padding (safe area)
  EdgeInsets get devicePadding => MediaQuery.of(this).padding;

  /// Get device view insets (keyboard)
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Get keyboard height
  double get keyboardHeight => viewInsets.bottom;

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Show snackbar
  void showSnackBar(String message,
      {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        duration: duration,
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message,
      {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Pop with result
  void popWithResult<T>(T result) {
    Navigator.of(this).pop(result);
  }

  /// Push named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace current route
  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed(routeName, arguments: arguments);
  }
}
