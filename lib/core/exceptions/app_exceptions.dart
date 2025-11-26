/// Custom exception classes for the application
/// Provides structured error handling across the app
library app_exceptions;

/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

/// Thrown when authentication fails
class AuthException extends AppException {
  AuthException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'AUTH_ERROR');
}

/// Thrown when network request fails
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'NETWORK_ERROR');
}

/// Thrown when data validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    String? code,
    super.originalException,
    this.fieldErrors,
  }) : super(code: code ?? 'VALIDATION_ERROR');
}

/// Thrown when resource is not found
class NotFoundException extends AppException {
  NotFoundException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'NOT_FOUND');
}

/// Thrown when user lacks permission
class PermissionException extends AppException {
  PermissionException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'PERMISSION_DENIED');
}

/// Thrown when database operation fails
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'DATABASE_ERROR');
}

/// Thrown when cache operation fails
class CacheException extends AppException {
  CacheException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'CACHE_ERROR');
}

/// Thrown for unexpected errors
class UnexpectedException extends AppException {
  UnexpectedException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(code: code ?? 'UNEXPECTED_ERROR');
}
