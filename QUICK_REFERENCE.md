# HealthSphere - Quick Reference Guide

## File Structure at a Glance

```
lib/
├── core/                    # Core application layer
│   ├── config/             # App configuration
│   ├── constants/          # App constants
│   ├── di/                 # Dependency injection
│   ├── exceptions/         # Custom exceptions
│   ├── extensions/         # Dart extensions
│   ├── logging/            # Logging system
│   ├── result/             # Result type
│   ├── services/           # Base service
│   └── utils/              # Utilities
├── shared/                 # Shared components
│   └── widgets/            # Reusable widgets
├── features/               # Feature modules (recommended)
├── screens/                # Current screens (legacy)
├── services/               # Current services (legacy)
├── models/                 # Data models
├── providers/              # State management
├── theme/                  # Theme configuration
└── main.dart              # Entry point
```

## Common Tasks

### Create a New Feature

```bash
# 1. Create directory structure
lib/features/feature_name/
├── models/
├── services/
├── providers/
├── screens/
└── widgets/

# 2. Create model
# 3. Create service extending BaseService
# 4. Create provider with ChangeNotifier
# 5. Create screen using provider
# 6. Register provider in main.dart
# 7. Add route in main.dart
```

### Use Error Handling

```dart
try {
  await service.operation();
} on AuthException catch (e) {
  // Handle auth error
} on NotFoundException catch (e) {
  // Handle not found
} on AppException catch (e) {
  // Handle other errors
}
```

### Add Logging

```dart
AppLogger.debug('Message');
AppLogger.info('Message');
AppLogger.warning('Message');
AppLogger.error('Message', error: e, stackTrace: st);
AppLogger.fatal('Message', error: e);
```

### Use Extensions

```dart
// String
if (email.isValidEmail) {}
String capitalized = text.capitalize;

// Context
if (context.isMobile) {}
double width = context.screenWidth;
context.showSnackBar('Message');
context.pushNamed('/route');
```

### Create Reusable Widget

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Use Form Validation

```dart
AppTextField(
  label: 'Email',
  validator: Validators.validateEmail,
)
```

### Access Configuration

```dart
String appName = AppConfig.appName;
int pageSize = AppConfig.defaultPageSize;
Duration timeout = AppConfig.apiTimeout;
```

### Use Service Locator

```dart
// Register
serviceLocator.register<MyService>(MyService());

// Get
final service = serviceLocator.get<MyService>();
```

### Handle Loading States

```dart
Consumer<MyProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return const AppLoadingIndicator();
    }
    if (provider.error != null) {
      return AppErrorState(
        title: 'Error',
        message: provider.error,
        onRetry: () => provider.load(),
      );
    }
    if (provider.items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox,
        title: 'No items',
      );
    }
    return ListView.builder(
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(provider.items[index].name));
      },
    );
  },
)
```

## Widget Components

### AppButton
```dart
AppButton(
  label: 'Submit',
  onPressed: () {},
  isLoading: false,
  isEnabled: true,
)
```

### AppOutlinedButton
```dart
AppOutlinedButton(
  label: 'Cancel',
  onPressed: () {},
)
```

### AppTextField
```dart
AppTextField(
  label: 'Email',
  hint: 'Enter email',
  keyboardType: TextInputType.emailAddress,
  validator: Validators.validateEmail,
  onChanged: (value) {},
)
```

### AppCard
```dart
AppCard(
  child: Text('Content'),
  onTap: () {},
  elevation: 2,
)
```

### AppCardWithHeader
```dart
AppCardWithHeader(
  title: 'Title',
  content: Text('Content'),
  trailing: Icon(Icons.arrow_forward),
)
```

### StatCard
```dart
StatCard(
  label: 'Total Users',
  value: '1,234',
  icon: Icons.people,
)
```

### AppLoadingIndicator
```dart
const AppLoadingIndicator(
  message: 'Loading...',
)
```

### AppEmptyState
```dart
AppEmptyState(
  icon: Icons.inbox,
  title: 'No items',
  subtitle: 'Create one to get started',
  action: AppButton(
    label: 'Create',
    onPressed: () {},
  ),
)
```

### AppErrorState
```dart
AppErrorState(
  title: 'Error',
  message: 'Something went wrong',
  onRetry: () {},
)
```

## Constants Reference

```dart
// Collections
AppConstants.usersCollection
AppConstants.patientsCollection
AppConstants.appointmentsCollection

// Roles
AppConstants.roleAdmin
AppConstants.roleHealthWorker
AppConstants.rolePatient

// Status
AppConstants.appointmentPending
AppConstants.appointmentApproved
AppConstants.consultationCompleted

// Validation
AppConstants.minPasswordLength
AppConstants.maxNameLength

// Pagination
AppConstants.defaultPageSize
AppConstants.maxPageSize

// Routes
AppRoutes.login
AppRoutes.adminDashboard
AppRoutes.patients
```

## Validators

```dart
Validators.validateEmail(value)
Validators.validatePassword(value)
Validators.validatePhone(value)
Validators.validateRequired(value)
Validators.validateMinLength(value, 8)
Validators.validateMaxLength(value, 100)
Validators.validateNumeric(value)
Validators.validateUrl(value)
Validators.validateDate(value)
Validators.validatePasswordsMatch(value, confirmValue)
```

## Service Pattern

```dart
class MyService extends BaseService {
  Future<List<Item>> getItems() async {
    return executeDbOperation(
      () async {
        final snapshot = await firestore.collection('items').get();
        return snapshot.docs
            .map((doc) => Item.fromJson(doc.data()))
            .toList();
      },
      operationName: 'getItems',
    );
  }
}
```

## Provider Pattern

```dart
class MyProvider with ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  
  List<Item> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _items = await _service.getItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## Documentation Files

| File | Purpose |
|------|---------|
| ARCHITECTURE.md | Detailed architecture guide |
| BEST_PRACTICES.md | Coding standards and patterns |
| DEVELOPMENT_GUIDE.md | Step-by-step development guide |
| SYSTEM_IMPROVEMENTS.md | Summary of improvements |
| QUICK_REFERENCE.md | This file |

## Key Files Location

| Component | Location |
|-----------|----------|
| App Config | `lib/core/config/app_config.dart` |
| Exceptions | `lib/core/exceptions/app_exceptions.dart` |
| Logger | `lib/core/logging/app_logger.dart` |
| Base Service | `lib/core/services/base_service.dart` |
| Service Locator | `lib/core/di/service_locator.dart` |
| Validators | `lib/core/utils/validators.dart` |
| Constants | `lib/core/constants/app_constants.dart` |
| Buttons | `lib/shared/widgets/app_button.dart` |
| Text Field | `lib/shared/widgets/app_text_field.dart` |
| Cards | `lib/shared/widgets/app_card.dart` |
| Loading | `lib/shared/widgets/app_loading.dart` |

## Tips & Tricks

### Use const Constructors
```dart
const MyWidget() // Good
MyWidget()       // Avoid
```

### Extract Complex Widgets
```dart
// Break down large build methods into smaller methods
Widget _buildHeader() => ...
Widget _buildContent() => ...
```

### Use Consumer for Selective Rebuilds
```dart
Consumer<MyProvider>(
  builder: (context, provider, child) {
    return Text(provider.value);
  },
)
```

### Cache Data
```dart
if (_cache.containsKey(key)) {
  return _cache[key];
}
```

### Use Lazy Loading
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)
```

### Profile Performance
```bash
flutter run --profile
# Open DevTools: flutter pub global run devtools
```

## Common Patterns

### Async with Loading State
```dart
Future<void> loadData() async {
  _isLoading = true;
  notifyListeners();
  try {
    _data = await _service.getData();
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### Pagination
```dart
Future<void> loadMore() async {
  final newItems = await _service.getItems(
    page: _currentPage,
    pageSize: AppConstants.defaultPageSize,
  );
  _items.addAll(newItems);
  _currentPage++;
  notifyListeners();
}
```

### Search/Filter
```dart
void search(String query) {
  _filteredItems = _items
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  notifyListeners();
}
```

## Debugging

### Enable Debug Logging
```dart
EnvironmentConfig.current = Environment.development;
```

### View Logs
```bash
flutter logs
```

### Use DevTools
```bash
flutter pub global activate devtools
devtools
```

## Useful Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run app
flutter run

# Build release
flutter build apk --release

# Run tests
flutter test

# Format code
dart format lib/

# Analyze code
dart analyze
```

## Need Help?

1. Check the relevant documentation file
2. Review existing implementations
3. Search the codebase for similar patterns
4. Consult with the team

---

**Last Updated**: November 2024
**Version**: 1.0.0
