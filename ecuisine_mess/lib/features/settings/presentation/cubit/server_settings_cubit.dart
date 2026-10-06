import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/config/app_config.dart';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/config/api_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'server_settings_state.dart';

class ServerSettingsCubit extends Cubit<ServerSettingsState> {
  ServerSettingsCubit({
    required AppConfig appConfig,
    required ApiClient apiClient,
  })  : _appConfig = appConfig,
        _apiClient = apiClient,
        super(ServerSettingsState(baseUrl: appConfig.baseUrl));

  final AppConfig _appConfig;
  final ApiClient _apiClient;

  void urlChanged(String value) {
    emit(
      state.copyWith(
        draftUrl: value,
        status: ServerSettingsStatus.editing,
        clearMessage: true,
      ),
    );
  }

  Future<void> saveAndApply() async {
    emit(state.copyWith(status: ServerSettingsStatus.testing, clearMessage: true));
    try {
      final normalized = AppConfig.normalize(state.draftUrl.trim());
      final ok = await _ping(normalized);
      if (!ok) {
        emit(
          state.copyWith(
            status: ServerSettingsStatus.error,
            message: 'Server did not respond as online',
          ),
        );
        return;
      }
      await _appConfig.setBaseUrl(normalized);
      _apiClient.updateBaseUrl(normalized);
      // Strangler: keep legacy ApiService base URL in sync.
      ApiConfig.baseUrl = normalized;
      emit(
        state.copyWith(
          status: ServerSettingsStatus.ok,
          baseUrl: normalized,
          draftUrl: normalized,
          message: 'API URL updated to: $normalized',
        ),
      );
    } on ArgumentError catch (e) {
      emit(
        state.copyWith(
          status: ServerSettingsStatus.error,
          message: e.message?.toString() ?? 'Invalid URL',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ServerSettingsStatus.error,
          message: e.toString(),
        ),
      );
    }
  }

  Future<bool> _ping(String root) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: '$root/api/v1',
        connectTimeout: AppConstants.healthTimeout,
        receiveTimeout: AppConstants.healthTimeout,
      ),
    );
    try {
      final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.health);
      final data = res.data;
      return res.statusCode == 200 &&
          data != null &&
          data['status'] == 'online';
    } catch (_) {
      return false;
    } finally {
      dio.close();
    }
  }
}
