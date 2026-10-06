import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/error/failures.dart';

Failure mapException(Object error) {
  if (error is Failure) return error;
  if (error is UnauthorizedException) {
    return UnauthorizedFailure(error.message);
  }
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }
  if (error is NotFoundException) {
    return NotFoundFailure(error.message);
  }
  if (error is ConflictException) {
    return ConflictFailure(
      error.message,
      code: error.code,
      context: error.context,
    );
  }
  if (error is ValidationException) {
    return ValidationFailure(error.message, fieldErrors: error.fieldErrors);
  }
  if (error is ServerException) {
    return ServerFailure(error.message);
  }
  if (error is AppException) {
    return ServerFailure(error.message);
  }
  return UnexpectedFailure(error.toString());
}
