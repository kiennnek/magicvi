abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiException extends AppException {
  const ApiException(String message, [int? code]) : super(message, code);

  @override
  String toString() => 'ApiException: $message${code != null ? ' (Code: $code)' : ''}';
}

class DatabaseException extends AppException {
  const DatabaseException(String message) : super(message);

  @override
  String toString() => 'DatabaseException: $message';
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message);

  @override
  String toString() => 'ValidationException: $message';
}

class CacheException extends AppException {
  const CacheException(String message) : super(message);

  @override
  String toString() => 'CacheException: $message';
}

class AuthException extends AppException {
  const AuthException(String message, [int? code]) : super(message, code);

  @override
  String toString() => 'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

