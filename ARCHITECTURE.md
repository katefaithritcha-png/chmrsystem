# HealthSphere - Professional Architecture Guide

## Overview
HealthSphere is a Community Health Records Management System built with Flutter, following clean architecture principles and professional software design patterns.

## Project Structure

```
lib/
├── core/                          # Core application layer
│   ├── config/                    # Configuration management
│   │   └── app_config.dart       # App constants and environment settings
│   ├── exceptions/                # Custom exception classes
│   │   └── app_exceptions.dart   # Structured error handling
│   ├── extensions/                # Dart extensions
│   │   ├── context_extensions.dart
│   │   └── string_extensions.dart
│   ├── logging/                   # Logging system
│   │   └── app_logger.dart       # Professional logging
│   ├── result/                    # Result type for error handling
│   │   └── result.dart           # Success/Failure pattern
│   ├── services/                  # Base service classes
│   │   └── base_service.dart     # Common service functionality
│   └── di/                        # Dependency injection
│       └── service_locator.dart  # Service locator pattern
│
├── shared/                        # Shared components
│   └── widgets/                   # Reusable UI components
│       ├── app_button.dart       # Button variants
│       ├── app_text_field.dart   # Text input
│       ├── app_card.dart         # Card components
│       └── ...
│
├── features/                      # Feature modules (recommended structure)
│   ├── auth/
│   │   ├── models/
│   │   ├── services/
│   │   ├── providers/
│   │   └── screens/
│   ├── patients/
│   ├── appointments/
│   └── ...
│
├── screens/                       # Current screens (legacy)
├── services/                      # Current services (legacy)
├── models/                        # Current models
├── providers/                     # State management
├── widgets/                       # Legacy widgets
├── theme/                         # Theme configuration
├── utils/                         # Utility functions
│
├── main.dart                      # Application entry point
└── firebase_options.dart          # Firebase configuration
```

## Core Architecture Principles

### 1. Clean Architecture
- **Separation of Concerns**: Each layer has a specific responsibility
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Testability**: Components are designed to be easily testable

### 2. Error Handling
Use the custom exception hierarchy for structured error handling:

```dart
try {
  final result = await userService.getUser(userId);
} on AuthException catch (e) {
  // Handle authentication errors
} on NotFoundException catch (e) {
  // Handle not found errors
} on AppException catch (e) {
  // Handle other app errors
}
```

### 3. Logging
Use the centralized logging system:

```dart
AppLogger.debug('Debug message');
AppLogger.info('Info message');
AppLogger.warning('Warning message');
AppLogger.error('Error message', error: e, stackTrace: st);
AppLogger.fatal('Fatal error', error: e);
```

### 4. Result Type Pattern
Use Result type for functional error handling:

```dart
Future<Result<User>> getUser(String id) async {
  try {
    final user = await _firestore.collection('users').doc(id).get();
    return Success(User.fromJson(user.data()));
  } catch (e) {
    return Failure(exception: e as Exception);
  }
}

// Usage
final result = await userService.getUser(userId);
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('User: ${user.name}'),
);
```

### 5. Service Layer
All services should extend `BaseService` for consistent error handling:

```dart
class UserService extends BaseService {
  Future<User> getUser(String id) async {
    return executeDbOperation(
      () async {
        final doc = await firestore.collection('users').doc(id).get();
        return User.fromJson(doc.data()!);
      },
      operationName: 'getUser($id)',
    );
  }
}
```

### 6. Dependency Injection
Use the service locator for dependency management:

```dart
// Register services
serviceLocator.register<UserService>(UserService());
serviceLocator.registerLazySingleton<AuthService>(() => AuthService());

// Get services
final userService = serviceLocator.get<UserService>();
```

## State Management

The project uses Provider for state management:

```dart
// Create a provider
class UserProvider with ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  Future<void> loadUser(String id) async {
    _user = await userService.getUser(id);
    notifyListeners();
  }
}

// Use in widget
Consumer<UserProvider>(
  builder: (context, provider, child) {
    return Text(provider.user?.name ?? 'Loading...');
  },
)
```

## Reusable Widgets

### AppButton
```dart
AppButton(
  label: 'Submit',
  onPressed: () {},
  isLoading: false,
)
```

### AppTextField
```dart
AppTextField(
  label: 'Email',
  hint: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Required';
    return null;
  },
)
```

### AppCard
```dart
AppCard(
  child: Text('Card content'),
  onTap: () {},
)
```

## Configuration

### App Config
All app constants are centralized in `AppConfig`:

```dart
AppConfig.appName           // 'HealthSphere'
AppConfig.apiTimeout        // Duration(seconds: 30)
AppConfig.defaultPageSize   // 20
AppConfig.minPasswordLength // 8
```

### Environment Config
Manage environment-specific settings:

```dart
EnvironmentConfig.current = Environment.production;
if (EnvironmentConfig.isDevelopment) {
  // Dev-only code
}
```

## Best Practices

### 1. Naming Conventions
- Classes: PascalCase (e.g., `UserService`)
- Functions/Methods: camelCase (e.g., `getUser()`)
- Constants: camelCase (e.g., `maxRetries`)
- Private members: prefix with `_` (e.g., `_firestore`)

### 2. Documentation
- Add doc comments to public APIs
- Use `///` for documentation comments
- Include examples in complex functions

### 3. Error Handling
- Always catch specific exceptions first
- Log errors with context
- Provide user-friendly error messages

### 4. Performance
- Use `const` constructors
- Implement `shouldRebuild` in providers
- Cache frequently accessed data
- Use lazy loading for large lists

### 5. Testing
- Write unit tests for services
- Write widget tests for UI components
- Use mocks for external dependencies

## Migration Guide

### From Legacy to New Architecture

1. **Create Feature Module**
   ```
   features/feature_name/
   ├── models/
   ├── services/
   ├── providers/
   └── screens/
   ```

2. **Extract Service**
   ```dart
   class FeatureService extends BaseService {
     // Implementation
   }
   ```

3. **Create Provider**
   ```dart
   class FeatureProvider with ChangeNotifier {
     // State management
   }
   ```

4. **Update Screens**
   - Use new widgets from `shared/widgets/`
   - Use providers for state management
   - Handle errors with custom exceptions

## Common Patterns

### Async Operations with Loading State
```dart
class DataProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load data
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Pagination
```dart
List<QueryConstraint> buildPaginationConstraints(int page, int pageSize) {
  return [
    OrderConstraint('createdAt', descending: true),
    LimitConstraint(pageSize),
  ];
}
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Support

For questions or issues regarding the architecture, please refer to this document or contact the development team.
