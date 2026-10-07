import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/unauthorized_handler.dart';
import 'package:ecuisine_mess/core/services/mess_server_signals.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this._unauthorized);

  final UnauthorizedHandler _unauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final skipUnauthorized = err.requestOptions.extra['skipUnauthorized'] == true;
    final status = err.response?.statusCode;
    final data = err.response?.data;
    final message = _messageFromBody(data, status);

    if (status == 401) {
      if (!skipUnauthorized) {
        _unauthorized.notify();
      }
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: UnauthorizedException(message),
        ),
      );
      return;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      MessServerSignals.instance.notifyConnectionLost();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          type: err.type,
          error: const NetworkException(),
        ),
      );
      return;
    }

    if (status == 404) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: NotFoundException(message),
        ),
      );
      return;
    }

    if (status == 409) {
      final code = _errorCode(data) ?? 'CONFLICT';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: ConflictException(message, code: code, context: _context(data)),
        ),
      );
      return;
    }

    if (status == 400 || status == 422) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: ValidationException(
            message,
            fieldErrors: _fieldErrors(data),
            statusCode: status ?? 400,
          ),
        ),
      );
      return;
    }

    if (status != null && status >= 500) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: ServerException(message, status),
        ),
      );
      return;
    }

    if (err.error is AppException) {
      handler.next(err);
      return;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: AppException(message, statusCode: status),
      ),
    );
  }

  String _messageFromBody(dynamic data, int? statusCode) {
    if (data is Map) {
      final message = data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final parts = <String>[];
        for (final item in detail) {
          if (item is Map && item['msg'] != null) {
            parts.add(item['msg'].toString());
          } else if (item != null) {
            parts.add(item.toString());
          }
        }
        if (parts.isNotEmpty) return parts.join('; ');
      }
    }
    return 'Request failed (${statusCode ?? 'network'})';
  }

  String? _errorCode(dynamic data) {
    if (data is Map && data['error_code'] != null) {
      return data['error_code'].toString();
    }
    return null;
  }

  Map<String, dynamic> _context(dynamic data) {
    if (data is Map) {
      final details = data['details'];
      if (details is Map<String, dynamic>) return details;
      if (details is Map) return Map<String, dynamic>.from(details);
    }
    return const {};
  }

  Map<String, String> _fieldErrors(dynamic data) {
    if (data is! Map) return const {};
    final detail = data['detail'];
    if (detail is! List) return const {};
    final out = <String, String>{};
    for (final item in detail) {
      if (item is Map) {
        final loc = item['loc'];
        final msg = item['msg']?.toString() ?? '';
        if (loc is List && loc.isNotEmpty) {
          out[loc.last.toString()] = msg;
        }
      }
    }
    return out;
  }
}
