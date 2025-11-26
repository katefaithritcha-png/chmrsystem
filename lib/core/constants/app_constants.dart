/// Application-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'HealthSphere';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String patientsCollection = 'patients';
  static const String appointmentsCollection = 'appointments';
  static const String consultationsCollection = 'consultations';
  static const String medicinesCollection = 'medicines';
  static const String inventoryCollection = 'inventory';
  static const String auditLogsCollection = 'audit_logs';
  static const String notificationsCollection = 'notifications';
  static const String alertsCollection = 'alerts';
  static const String populationCollection = 'population';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleHealthWorker = 'health_worker';
  static const String rolePatient = 'patient';

  // Appointment Status
  static const String appointmentPending = 'pending';
  static const String appointmentApproved = 'approved';
  static const String appointmentRejected = 'rejected';
  static const String appointmentCompleted = 'completed';
  static const String appointmentCancelled = 'cancelled';

  // Consultation Status
  static const String consultationPending = 'pending';
  static const String consultationInProgress = 'in_progress';
  static const String consultationCompleted = 'completed';

  // Notification Types
  static const String notificationAppointment = 'appointment';
  static const String notificationConsultation = 'consultation';
  static const String notificationAlert = 'alert';
  static const String notificationMessage = 'message';

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 254;
  static const int maxPhoneLength = 20;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 1;

  // Cache Duration
  static const Duration userCacheDuration = Duration(hours: 1);
  static const Duration patientCacheDuration = Duration(hours: 2);
  static const Duration appointmentCacheDuration = Duration(minutes: 30);
  static const Duration appointmentListCacheDuration = Duration(minutes: 15);

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration downloadTimeout = Duration(minutes: 5);

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Shared Preferences Keys
  static const String prefOnboardingSeen = 'onboarding_seen';
  static const String prefUserRole = 'user_role';
  static const String prefUserId = 'user_id';
  static const String prefUserEmail = 'user_email';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefLastSyncTime = 'last_sync_time';

  // Error Messages
  static const String errorNetworkConnection = 'Network connection failed';
  static const String errorTimeout = 'Request timed out';
  static const String errorUnauthorized = 'Unauthorized access';
  static const String errorForbidden = 'Access forbidden';
  static const String errorNotFound = 'Resource not found';
  static const String errorServerError = 'Server error occurred';
  static const String errorUnexpected = 'An unexpected error occurred';
  static const String errorValidation = 'Validation failed';
  static const String errorEmptyField = 'This field cannot be empty';
  static const String errorInvalidEmail = 'Invalid email address';
  static const String errorInvalidPhone = 'Invalid phone number';
  static const String errorPasswordTooShort = 'Password is too short';
  static const String errorPasswordMismatch = 'Passwords do not match';

  // Success Messages
  static const String successSaved = 'Saved successfully';
  static const String successCreated = 'Created successfully';
  static const String successUpdated = 'Updated successfully';
  static const String successDeleted = 'Deleted successfully';
  static const String successLoggedIn = 'Logged in successfully';
  static const String successLoggedOut = 'Logged out successfully';

  // Date/Time Formats
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatISO = 'yyyy-MM-dd';
  static const String timeFormatDisplay = 'hh:mm a';
  static const String dateTimeFormatDisplay = 'MMM dd, yyyy hh:mm a';

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  // Limits
  static const int maxUploadFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxImageDimension = 2048;
  static const int maxConcurrentRequests = 5;
  static const int maxCacheSize = 100;

  // Default Values
  static const String defaultCountryCode = '+1';
  static const String defaultLanguage = 'en';
  static const String defaultTimeZone = 'UTC';
}

/// Route constants
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String adminDashboard = '/admin';
  static const String workerDashboard = '/worker';
  static const String patientDashboard = '/patient';
  static const String users = '/users';
  static const String patients = '/patients';
  static const String reports = '/reports';
  static const String consultation = '/consultation';
  static const String consultationNew = '/consultation/new';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String records = '/records';
  static const String audit = '/audit';
  static const String backup = '/backup';
  static const String appointments = '/appointments';
  static const String appointmentsApprovals = '/appointments/approvals';
  static const String inventory = '/inventory';
  static const String population = '/population';
  static const String home = '/home';
  static const String chrmsAlertsNew = '/chrms-alerts/new';
}

/// Asset paths
class AppAssets {
  AppAssets._();

  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';

  // Images
  static const String logoImage = '${imagesPath}logo.png';
  static const String splashImage = '${imagesPath}splash.png';
  static const String onboardingImage = '${imagesPath}onboarding.png';

  // Icons
  static const String homeIcon = '${iconsPath}home.svg';
  static const String userIcon = '${iconsPath}user.svg';
  static const String settingsIcon = '${iconsPath}settings.svg';
}
