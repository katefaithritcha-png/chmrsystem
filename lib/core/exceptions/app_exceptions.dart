/// Custom exception classes for the application
/// Provides structured error handling across the app

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
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'AUTH_ERROR',
          originalException: originalException,
        );
}

/// Thrown when network request fails
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'NETWORK_ERROR',
          originalException: originalException,
        );
}

/// Thrown when data validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required String message,
    String? code,
    dynamic originalException,
    this.fieldErrors,
  }) : super(
          message: message,
          code: code ?? 'VALIDATION_ERROR',
          originalException: originalException,
        );
}

/// Thrown when resource is not found
class NotFoundException extends AppException {
  NotFoundException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'NOT_FOUND',
          originalException: originalException,
        );
}

/// Thrown when user lacks permission
class PermissionException extends AppException {
  PermissionException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'PERMISSION_DENIED',
          originalException: originalException,
        );
}

/// Thrown when database operation fails
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'DATABASE_ERROR',
          originalException: originalException,
        );
}

/// Thrown when cache operation fails
class CacheException extends AppException {
  CacheException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'CACHE_ERROR',
          originalException: originalException,
        );
}

/// Thrown for unexpected errors
class UnexpectedException extends AppException {
  UnexpectedException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
          message: message,
          code: code ?? 'UNEXPECTED_ERROR',
          originalException: originalException,
        );
}
