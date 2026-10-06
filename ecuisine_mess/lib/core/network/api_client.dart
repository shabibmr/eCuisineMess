import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/config/app_config.dart';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/core/network/interceptors/auth_interceptor.dart';
import 'package:ecuisine_mess/core/network/interceptors/error_interceptor.dart';
import 'package:ecuisine_mess/core/network/session_token_holder.dart';
import 'package:ecuisine_mess/core/network/unauthorized_handler.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SessionTokenHolder session,
    required UnauthorizedHandler unauthorized,
  }) : _config = config {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${config.baseUrl}/api/v1',
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      AuthInterceptor(session),
      ErrorInterceptor(unauthorized),
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) {
            final text = obj.toString();
            if (text.contains('Authorization') || text.contains('password')) {
              return;
            }
            debugPrint(text);
          },
        ),
    ]);
  }

  final AppConfig _config;
  late final Dio _dio;

  Dio get dio => _dio;

  AppConfig get config => _config;

  void updateBaseUrl(String root) {
    _dio.options.baseUrl = '$root/api/v1';
  }
}
