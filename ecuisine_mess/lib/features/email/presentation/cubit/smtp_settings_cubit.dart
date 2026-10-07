import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';
import 'package:ecuisine_mess/features/email/domain/repositories/smtp_settings_repository.dart';
import 'package:ecuisine_mess/features/email/domain/services/email_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum SmtpSettingsStatus { initial, loading, loaded, saving, saved, error }
enum SmtpTestStatus { initial, testing, success, failure }

class SmtpSettingsState extends Equatable {
  const SmtpSettingsState({
    this.status = SmtpSettingsStatus.initial,
    this.testStatus = SmtpTestStatus.initial,
    this.settings = const SmtpSettings(),
    this.message,
    this.testMessage,
  });

  final SmtpSettingsStatus status;
  final SmtpTestStatus testStatus;
  final SmtpSettings settings;
  final String? message;
  final String? testMessage;

  SmtpSettingsState copyWith({
    SmtpSettingsStatus? status,
    SmtpTestStatus? testStatus,
    SmtpSettings? settings,
    String? message,
    String? testMessage,
    bool clearMessage = false,
    bool clearTestMessage = false,
  }) {
    return SmtpSettingsState(
      status: status ?? this.status,
      testStatus: testStatus ?? this.testStatus,
      settings: settings ?? this.settings,
      message: clearMessage ? null : (message ?? this.message),
      testMessage: clearTestMessage ? null : (testMessage ?? this.testMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        testStatus,
        settings,
        message,
        testMessage,
      ];
}

class SmtpSettingsCubit extends Cubit<SmtpSettingsState> {
  SmtpSettingsCubit({
    required SmtpSettingsRepository repository,
    required EmailService emailService,
  })  : _repository = repository,
        _emailService = emailService,
        super(SmtpSettingsState(settings: repository.currentSettings));

  final SmtpSettingsRepository _repository;
  final EmailService _emailService;

  Future<void> loadSettings() async {
    emit(state.copyWith(status: SmtpSettingsStatus.loading, clearMessage: true));
    try {
      final settings = await _repository.getSettings();
      emit(state.copyWith(
        status: SmtpSettingsStatus.loaded,
        settings: settings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SmtpSettingsStatus.error,
        message: 'Failed to load SMTP settings: $e',
      ));
    }
  }

  Future<void> saveSettings(SmtpSettings newSettings) async {
    emit(state.copyWith(status: SmtpSettingsStatus.saving, clearMessage: true));
    try {
      await _repository.saveSettings(newSettings);
      emit(state.copyWith(
        status: SmtpSettingsStatus.saved,
        settings: newSettings,
        message: 'SMTP settings successfully saved to Firestore.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SmtpSettingsStatus.error,
        message: 'Failed to save settings: $e',
      ));
    }
  }

  Future<void> testConnection(String testRecipient) async {
    if (testRecipient.trim().isEmpty) {
      emit(state.copyWith(
        testStatus: SmtpTestStatus.failure,
        testMessage: 'Please enter a test recipient email address',
      ));
      return;
    }

    emit(state.copyWith(
      testStatus: SmtpTestStatus.testing,
      clearTestMessage: true,
    ));

    final result = await _emailService.testConnection(
      testRecipient: testRecipient.trim(),
    );

    if (result.success) {
      emit(state.copyWith(
        testStatus: SmtpTestStatus.success,
        testMessage: 'Test email successfully dispatched!',
      ));
    } else {
      emit(state.copyWith(
        testStatus: SmtpTestStatus.failure,
        testMessage: result.errorMessage ?? 'Connection test failed',
      ));
    }
  }

  void resetMessages() {
    emit(state.copyWith(
      status: SmtpSettingsStatus.loaded,
      testStatus: SmtpTestStatus.initial,
      clearMessage: true,
      clearTestMessage: true,
    ));
  }
}
