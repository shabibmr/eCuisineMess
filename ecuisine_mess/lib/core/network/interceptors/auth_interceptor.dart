import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/network/session_token_holder.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);

  final SessionTokenHolder _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skipAuth = options.extra['skipAuth'] == true;
    final token = _session.token;
    if (!skipAuth && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
