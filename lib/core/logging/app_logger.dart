import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Logging levels
enum LogLevel { debug, info, warning, error, fatal }

/// Professional logging system for the application
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  /// Log debug message
  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log info message
  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log warning message
  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log error message
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log fatal error
  static void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!EnvironmentConfig.enableDebugLogging && level == LogLevel.debug) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] [$levelName] $message';

    if (kDebugMode) {
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }

    // In production, send to crash reporting service
    if (EnvironmentConfig.isProduction && level == LogLevel.fatal) {
      _reportToService(logMessage, error, stackTrace);
    }
  }

  static void _reportToService(
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    // TODO: Implement crash reporting service integration
    // Example: Firebase Crashlytics, Sentry, etc.
  }
}
