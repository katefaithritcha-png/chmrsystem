/// Application configuration management
/// Handles environment-specific settings and app constants
class AppConfig {
  static const String appName = 'HealthSphere';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Community Health Records Management System';

  // API Configuration
  static const String firebaseProjectId = 'chmrsystem';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableOfflineMode = true;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Configuration
  static const Duration cacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 50;

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}

/// Environment-specific configuration
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment current = Environment.production;

  static bool get isDevelopment => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProduction => current == Environment.production;

  static bool get enableDebugLogging => isDevelopment || isStaging;
}
