// TODO(feat): Integrate into error handling — throw from supabase_provider, database_provider, etc.
abstract class AppException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppException({required this.message, this.cause, this.stackTrace});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

class AuthException extends AppException {
  const AuthException({required super.message, super.cause, super.stackTrace});
}

class ProcessingException extends AppException {
  const ProcessingException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
