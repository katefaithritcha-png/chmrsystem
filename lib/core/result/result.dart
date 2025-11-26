/// Result type for handling success and failure cases
/// Provides a functional approach to error handling
abstract class Result<T> {
  const Result();

  /// Map the success value
  Result<U> map<U>(U Function(T) f) {
    if (this is Success<T>) {
      return Success((this as Success<T>).data as U);
    }
    return this as Result<U>;
  }

  /// Fold the result into a single value
  U fold<U>(
    U Function(Failure) onFailure,
    U Function(T) onSuccess,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else if (this is Failure) {
      return onFailure(this as Failure);
    }
    throw UnimplementedError();
  }

  /// Get data or null
  T? getOrNull() {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure;
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Failure result containing exception
class Failure extends Result<Never> {
  final Exception exception;
  final String? message;
  final String? code;

  const Failure({
    required this.exception,
    this.message,
    this.code,
  });

  @override
  String toString() => 'Failure(${message ?? exception.toString()})';
}
