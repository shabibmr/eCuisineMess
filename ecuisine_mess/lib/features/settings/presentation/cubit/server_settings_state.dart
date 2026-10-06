part of 'server_settings_cubit.dart';

enum ServerSettingsStatus { initial, editing, testing, ok, error }

final class ServerSettingsState extends Equatable {
  ServerSettingsState({
    required this.baseUrl,
    String? draftUrl,
    this.status = ServerSettingsStatus.initial,
    this.message,
  }) : draftUrl = draftUrl ?? baseUrl;

  final String baseUrl;
  final String draftUrl;
  final ServerSettingsStatus status;
  final String? message;

  ServerSettingsState copyWith({
    String? baseUrl,
    String? draftUrl,
    ServerSettingsStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return ServerSettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      draftUrl: draftUrl ?? this.draftUrl,
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [baseUrl, draftUrl, status, message];
}
