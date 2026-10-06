class AppException implements Exception {
  const AppException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Server unreachable']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Session expired'])
      : super(message, statusCode: 401);
}

class NotFoundException extends AppException {
  const NotFoundException([String message = 'Not found'])
      : super(message, statusCode: 404);
}

class ConflictException extends AppException {
  const ConflictException(
    String message, {
    required this.code,
    this.context = const {},
  }) : super(message, statusCode: 409);
  final String code;
  final Map<String, dynamic> context;
}

class ValidationException extends AppException {
  const ValidationException(
    String message, {
    this.fieldErrors = const {},
    int statusCode = 400,
  }) : super(message, statusCode: statusCode);
  final Map<String, String> fieldErrors;
}

class ServerException extends AppException {
  const ServerException([String message = 'Server error', int statusCode = 500])
      : super(message, statusCode: statusCode);
}
