# HealthSphere - Development Guide

## Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Firebase CLI
- Android Studio or Xcode (for mobile development)

### Setup

1. **Clone and Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**
   ```bash
   firebase login
   firebase init
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure Overview

### Core Layer (`lib/core/`)
Foundation of the application with cross-cutting concerns.

- **config/**: Application configuration and constants
- **exceptions/**: Custom exception hierarchy
- **extensions/**: Dart extensions for common types
- **logging/**: Centralized logging system
- **result/**: Result type for functional error handling
- **services/**: Base service class with common functionality
- **di/**: Dependency injection setup
- **utils/**: Utility functions (validators, formatters, etc.)

### Shared Layer (`lib/shared/`)
Reusable components used across the application.

- **widgets/**: Reusable UI components
  - `AppButton`: Primary action button
  - `AppOutlinedButton`: Secondary action button
  - `AppTextField`: Text input field
  - `AppCard`: Card component
  - `AppLoadingIndicator`: Loading state
  - `AppEmptyState`: Empty state
  - `AppErrorState`: Error state

### Features Layer (`lib/features/`) - Recommended
Modular feature implementation (recommended for new features).

Each feature should follow this structure:
```
features/feature_name/
├── models/           # Data models
├── services/         # Business logic
├── providers/        # State management
├── screens/          # UI screens
└── widgets/          # Feature-specific widgets
```

### Legacy Layers
- **screens/**: Current screens (migrate to features)
- **services/**: Current services (migrate to features)
- **models/**: Data models
- **providers/**: State management
- **widgets/**: Legacy widgets
- **theme/**: Theme configuration
- **utils/**: Utility functions

## Common Development Tasks

### Creating a New Feature

1. **Create Feature Directory**
   ```
   lib/features/new_feature/
   ├── models/
   ├── services/
   ├── providers/
   ├── screens/
   └── widgets/
   ```

2. **Create Data Model**
   ```dart
   // lib/features/new_feature/models/item.dart
   class Item {
     final String id;
     final String name;
     
     Item({required this.id, required this.name});
     
     factory Item.fromJson(Map<String, dynamic> json) {
       return Item(
         id: json['id'],
         name: json['name'],
       );
     }
     
     Map<String, dynamic> toJson() {
       return {
         'id': id,
         'name': name,
       };
     }
   }
   ```

3. **Create Service**
   ```dart
   // lib/features/new_feature/services/item_service.dart
   import 'package:chmrsystem/core/services/base_service.dart';
   
   class ItemService extends BaseService {
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

4. **Create Provider**
   ```dart
   // lib/features/new_feature/providers/item_provider.dart
   import 'package:flutter/foundation.dart';
   
   class ItemProvider with ChangeNotifier {
     final ItemService _service = ItemService();
     
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

5. **Create Screen**
   ```dart
   // lib/features/new_feature/screens/item_list_screen.dart
   import 'package:flutter/material.dart';
   import 'package:provider/provider.dart';
   
   class ItemListScreen extends StatelessWidget {
     const ItemListScreen({Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('Items')),
         body: Consumer<ItemProvider>(
           builder: (context, provider, child) {
             if (provider.isLoading) {
               return const AppLoadingIndicator();
             }
             
             if (provider.error != null) {
               return AppErrorState(
                 title: 'Error',
                 message: provider.error,
                 onRetry: () => provider.loadItems(),
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
                 final item = provider.items[index];
                 return ListTile(title: Text(item.name));
               },
             );
           },
         ),
       );
     }
   }
   ```

6. **Register Provider in main.dart**
   ```dart
   MultiProvider(
     providers: [
       ChangeNotifierProvider(create: (_) => ItemProvider()),
       // ... other providers
     ],
     child: MyApp(),
   )
   ```

7. **Add Route in main.dart**
   ```dart
   routes: {
     '/items': (context) => const ItemListScreen(),
   }
   ```

### Adding a New Reusable Widget

1. **Create Widget File**
   ```dart
   // lib/shared/widgets/custom_widget.dart
   import 'package:flutter/material.dart';
   
   class CustomWidget extends StatelessWidget {
     final String label;
     final VoidCallback onPressed;
     
     const CustomWidget({
       Key? key,
       required this.label,
       required this.onPressed,
     }) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return // Implementation
     }
   }
   ```

2. **Export from shared/widgets**
   Create or update `lib/shared/widgets/index.dart`:
   ```dart
   export 'app_button.dart';
   export 'app_text_field.dart';
   export 'custom_widget.dart';
   ```

### Handling Errors

Use the custom exception hierarchy:

```dart
try {
  await userService.getUser(id);
} on AuthException catch (e) {
  context.showErrorSnackBar('Authentication failed');
} on NotFoundException catch (e) {
  context.showErrorSnackBar('User not found');
} on AppException catch (e) {
  AppLogger.error('Error', error: e);
  context.showErrorSnackBar('An error occurred');
}
```

### Adding Logging

```dart
import 'package:chmrsystem/core/logging/app_logger.dart';

// Debug
AppLogger.debug('Debug message');

// Info
AppLogger.info('User logged in');

// Warning
AppLogger.warning('Cache miss for user $id');

// Error
AppLogger.error('Failed to fetch user', error: e, stackTrace: st);

// Fatal
AppLogger.fatal('Critical error', error: e);
```

### Using Extensions

```dart
// String extensions
String email = "user@example.com";
if (email.isValidEmail) {
  // Valid email
}

// Context extensions
if (context.isMobile) {
  // Mobile layout
}

double screenWidth = context.screenWidth;
bool isKeyboardVisible = context.isKeyboardVisible;

context.showSnackBar('Success!');
context.showErrorSnackBar('Error occurred');
context.pushNamed('/items');
```

### Form Validation

```dart
import 'package:chmrsystem/core/utils/validators.dart';

AppTextField(
  label: 'Email',
  validator: Validators.validateEmail,
)

AppTextField(
  label: 'Password',
  validator: Validators.validatePassword,
)

AppTextField(
  label: 'Phone',
  validator: Validators.validatePhone,
)
```

## State Management

### Using Provider

```dart
// Read-only
final items = context.read<ItemProvider>().items;

// Watch for changes
Consumer<ItemProvider>(
  builder: (context, provider, child) {
    return Text('Items: ${provider.items.length}');
  },
)

// Select specific value
Selector<ItemProvider, int>(
  selector: (context, provider) => provider.items.length,
  builder: (context, count, child) {
    return Text('Count: $count');
  },
)
```

## Performance Tips

1. **Use const constructors** whenever possible
2. **Extract complex widgets** into separate methods or classes
3. **Use ListView.builder** instead of ListView for large lists
4. **Cache data** appropriately to avoid unnecessary API calls
5. **Use shouldRebuild** in providers to prevent unnecessary rebuilds
6. **Profile your app** using Flutter DevTools

## Debugging

### Enable Debug Logging
```dart
EnvironmentConfig.current = Environment.development;
```

### Use Flutter DevTools
```bash
flutter pub global activate devtools
devtools
```

### Check Logs
```bash
flutter logs
```

## Testing

### Unit Tests
```dart
// test/services/user_service_test.dart
void main() {
  test('getUser returns user', () async {
    final service = UserService();
    final user = await service.getUser('123');
    expect(user.id, '123');
  });
}
```

### Widget Tests
```dart
// test/widgets/app_button_test.dart
void main() {
  testWidgets('AppButton calls onPressed', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Press',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    
    await tester.tap(find.byType(AppButton));
    expect(pressed, true);
  });
}
```

## Deployment

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

### Build Web
```bash
flutter build web --release
```

## Troubleshooting

### Common Issues

1. **Firebase not initializing**
   - Check `firebase_options.dart` is properly configured
   - Verify Firebase project credentials

2. **Provider not updating**
   - Ensure `notifyListeners()` is called
   - Check if using `Consumer` or `Selector` correctly

3. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check Dart version compatibility

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Documentation](https://pub.dev/packages/provider)

## Getting Help

- Check the ARCHITECTURE.md for design patterns
- Review BEST_PRACTICES.md for coding standards
- Check existing implementations for examples
- Consult the team for architectural decisions
