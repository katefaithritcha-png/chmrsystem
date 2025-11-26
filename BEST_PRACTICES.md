# HealthSphere - Best Practices Guide

## Code Quality Standards

### 1. Dart/Flutter Code Style

#### File Organization
```dart
// 1. Imports (organized by type)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';

// 2. Constants
const String appName = 'HealthSphere';

// 3. Main class/function
class UserScreen extends StatefulWidget {
  // Implementation
}

// 4. Helper classes/functions
class _UserListItem extends StatelessWidget {
  // Implementation
}
```

#### Naming Conventions
```dart
// Classes: PascalCase
class UserService {}
class PatientRecord {}

// Methods/Functions: camelCase
void loadUsers() {}
Future<User> getUser(String id) {}

// Constants: camelCase
const int maxRetries = 3;
const String apiBaseUrl = 'https://api.example.com';

// Private members: prefix with underscore
class UserService {
  final FirebaseFirestore _firestore;
  String? _cachedUserId;
  
  void _initialize() {}
}

// Variables: camelCase
String userName = 'John';
int userAge = 25;
bool isLoading = false;
```

### 2. Widget Best Practices

#### Use const Constructors
```dart
// Good
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Hello'),
    );
  }
}

// Avoid
class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Hello'),
    );
  }
}
```

#### Extract Complex Widgets
```dart
// Good
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildHeader(),
        _buildUserList(),
      ],
    );
  }
  
  Widget _buildHeader() => const Text('Users');
  Widget _buildUserList() => const SizedBox();
}

// Avoid
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Users'),
        // Long list building code...
      ],
    );
  }
}
```

#### Use Proper State Management
```dart
// Good - Using Provider
class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const AppLoadingIndicator();
        }
        return Text(provider.user?.name ?? 'No user');
      },
    );
  }
}

// Avoid - Direct state mutation
class UserScreen extends StatefulWidget {
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  User? user;
  
  @override
  void initState() {
    super.initState();
    // Fetching data in initState
  }
}
```

### 3. Service Layer Best Practices

#### Extend BaseService
```dart
// Good
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

// Avoid
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<User> getUser(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      return User.fromJson(doc.data()!);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}
```

#### Use Result Type for Error Handling
```dart
// Good
Future<Result<User>> getUser(String id) async {
  try {
    final user = await _fetchUser(id);
    return Success(user);
  } catch (e) {
    return Failure(exception: e as Exception);
  }
}

// Usage
final result = await userService.getUser(userId);
result.fold(
  (failure) => showError(failure.message),
  (user) => updateUI(user),
);

// Avoid
Future<User?> getUser(String id) async {
  try {
    return await _fetchUser(id);
  } catch (e) {
    return null;
  }
}
```

### 4. Error Handling

#### Use Custom Exceptions
```dart
// Good
try {
  await userService.getUser(id);
} on AuthException catch (e) {
  showErrorDialog('Authentication failed: ${e.message}');
} on NotFoundException catch (e) {
  showErrorDialog('User not found');
} on AppException catch (e) {
  AppLogger.error('Unexpected error', error: e);
  showErrorDialog('An error occurred');
}

// Avoid
try {
  await userService.getUser(id);
} catch (e) {
  print('Error: $e');
  showErrorDialog('Something went wrong');
}
```

#### Log Errors Properly
```dart
// Good
try {
  await operation();
} catch (e, stackTrace) {
  AppLogger.error(
    'Operation failed',
    error: e,
    stackTrace: stackTrace,
  );
}

// Avoid
try {
  await operation();
} catch (e) {
  print(e);
}
```

### 5. Performance Optimization

#### Use shouldRebuild in Providers
```dart
// Good
class UserProvider with ChangeNotifier {
  User? _user;
  
  void setUser(User user) {
    if (_user?.id != user.id) {
      _user = user;
      notifyListeners();
    }
  }
}

// Avoid
class UserProvider with ChangeNotifier {
  User? _user;
  
  void setUser(User user) {
    _user = user;
    notifyListeners(); // Always notifies
  }
}
```

#### Cache Data Appropriately
```dart
// Good
class UserService extends BaseService {
  final Map<String, User> _userCache = {};
  
  Future<User> getUser(String id) async {
    if (_userCache.containsKey(id)) {
      return _userCache[id]!;
    }
    
    final user = await _fetchUser(id);
    _userCache[id] = user;
    return user;
  }
}

// Avoid - No caching
class UserService extends BaseService {
  Future<User> getUser(String id) async {
    return _fetchUser(id); // Always fetches
  }
}
```

#### Use Lazy Loading for Lists
```dart
// Good
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserListItem(user: users[index]);
      },
    );
  }
}

// Avoid
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: users.map((user) => UserListItem(user: user)).toList(),
    );
  }
}
```

### 6. Documentation

#### Add Doc Comments
```dart
// Good
/// Fetches a user by their ID from the database.
/// 
/// Returns a [User] object if found, otherwise throws [NotFoundException].
/// 
/// Example:
/// ```dart
/// final user = await userService.getUser('user123');
/// print(user.name);
/// ```
Future<User> getUser(String id) async {
  // Implementation
}

// Avoid
Future<User> getUser(String id) async {
  // Implementation
}
```

#### Document Complex Logic
```dart
// Good
// Calculate age from birth date, accounting for leap years
int calculateAge(DateTime birthDate) {
  final today = DateTime.now();
  int age = today.year - birthDate.year;
  
  // Adjust if birthday hasn't occurred this year
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  
  return age;
}

// Avoid
int calculateAge(DateTime birthDate) {
  final today = DateTime.now();
  int age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age;
}
```

### 7. Testing

#### Write Testable Code
```dart
// Good - Dependency injection makes testing easy
class UserService extends BaseService {
  final FirebaseFirestore firestore;
  
  UserService({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;
  
  Future<User> getUser(String id) async {
    // Implementation
  }
}

// Test
void main() {
  test('getUser returns user', () async {
    final mockFirestore = MockFirebaseFirestore();
    final service = UserService(firestore: mockFirestore);
    
    final user = await service.getUser('123');
    expect(user.id, '123');
  });
}

// Avoid - Hard to test
class UserService extends BaseService {
  Future<User> getUser(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .get();
    return User.fromJson(doc.data()!);
  }
}
```

### 8. Security Best Practices

#### Never Hardcode Secrets
```dart
// Good - Use environment variables or secure storage
class ApiConfig {
  static String get apiKey => _getApiKey();
  
  static String _getApiKey() {
    // Retrieve from secure storage or environment
    return const String.fromEnvironment('API_KEY');
  }
}

// Avoid
class ApiConfig {
  static const String apiKey = 'sk-1234567890abcdef';
}
```

#### Validate User Input
```dart
// Good
String? validateEmail(String email) {
  if (email.isEmpty) return 'Email is required';
  if (!email.contains('@')) return 'Invalid email format';
  return null;
}

// Avoid
String email = userInput; // No validation
```

## Common Patterns

### Loading State Pattern
```dart
class DataProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Item> _items = [];
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Item> get items => _items;
  
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _items = await _service.getItems();
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Pagination Pattern
```dart
class PaginatedProvider with ChangeNotifier {
  int _currentPage = 1;
  final int _pageSize = 20;
  List<Item> _items = [];
  bool _hasMore = true;
  
  List<Item> get items => _items;
  bool get hasMore => _hasMore;
  
  Future<void> loadMore() async {
    if (!_hasMore) return;
    
    final newItems = await _service.getItems(
      page: _currentPage,
      pageSize: _pageSize,
    );
    
    if (newItems.length < _pageSize) {
      _hasMore = false;
    }
    
    _items.addAll(newItems);
    _currentPage++;
    notifyListeners();
  }
}
```

## Code Review Checklist

- [ ] Code follows naming conventions
- [ ] All public APIs have documentation
- [ ] Error handling is comprehensive
- [ ] No hardcoded values (use constants)
- [ ] Widgets use const constructors
- [ ] State management is appropriate
- [ ] No unnecessary rebuilds
- [ ] Performance is optimized
- [ ] Security best practices followed
- [ ] Tests are included for critical logic

## Resources

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Clean Code](https://www.oreilly.com/library/view/clean-code-a/9780136083238/)
