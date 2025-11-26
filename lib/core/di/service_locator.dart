/// Service locator for dependency injection
/// Provides centralized access to all application services
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  final Map<Type, dynamic> _services = {};

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Register a lazy singleton
  void registerLazySingleton<T>(T Function() factory) {
    late T instance;
    _services[T] = () {
      instance ??= factory();
      return instance;
    };
  }

  /// Get a service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered');
    }
    if (service is Function) {
      return service() as T;
    }
    return service as T;
  }

  /// Check if service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Unregister a service
  void unregister<T>() {
    _services.remove(T);
  }

  /// Clear all services
  void clear() {
    _services.clear();
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
