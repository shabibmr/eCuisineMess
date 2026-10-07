# Task Checklist: Email Service Module (flutter_bloc DI + Direct Firestore)

- [x] **Phase 1: Dependencies & Configuration**
  - [x] Add `mailer: ^7.2.0` to `ecuisine_mess/pubspec.yaml` and run `flutter pub get`
  - [x] Add Firestore constants to `ecuisine_mess/lib/core/config/constants.dart`

- [x] **Phase 2: Email Core Entities & Service**
  - [x] Implement `ecuisine_mess/lib/features/email/domain/entities/email_attachment.dart`
  - [x] Implement `ecuisine_mess/lib/features/email/domain/entities/email_send_result.dart`
  - [x] Define abstract `ecuisine_mess/lib/features/email/domain/services/email_service.dart` (with `EmailService.current` static accessor)
  - [x] Implement `ecuisine_mess/lib/features/email/data/services/mailer_email_service_impl.dart` (asynchronous, HTML templating, attachments)

- [x] **Phase 3: Firestore Settings Data Layer**
  - [x] Create `ecuisine_mess/lib/features/email/domain/entities/smtp_settings.dart`
  - [x] Create `ecuisine_mess/lib/features/email/data/models/smtp_settings_model.dart` (Firestore document parser + JSON)
  - [x] Create `ecuisine_mess/lib/features/email/data/datasources/smtp_firestore_datasource.dart` (Direct client Firestore REST API via Dio)
  - [x] Create `ecuisine_mess/lib/features/email/domain/repositories/smtp_settings_repository.dart`
  - [x] Implement `ecuisine_mess/lib/features/email/data/repositories/smtp_settings_repository_impl.dart` (Firestore + SharedPreferences cache fallback)

- [x] **Phase 4: State Management & DI (flutter_bloc only, No GetIt)**
  - [x] Implement `ecuisine_mess/lib/features/email/presentation/bloc/email_bloc.dart`
  - [x] Implement `ecuisine_mess/lib/features/email/presentation/cubit/smtp_settings_cubit.dart`
  - [x] Update `ecuisine_mess/lib/app.dart` with `MultiRepositoryProvider` (`EmailService`, `SmtpSettingsRepository`) and `MultiBlocProvider` (`EmailBloc`, `SmtpSettingsCubit`)

- [x] **Phase 5: UI Integration**
  - [x] Implement `ecuisine_mess/lib/features/email/presentation/widgets/smtp_settings_dialog.dart`
  - [x] Add SMTP Settings button to app bar in `ecuisine_mess/lib/shared/widgets/layout/app_shell.dart`
  - [x] Implement `ecuisine_mess/lib/features/reports/presentation/widgets/email_report_dialog.dart`
  - [x] Add "Email Report" action button in report view / tabs

- [x] **Phase 6: Verification & Tests**
  - [x] Create unit tests in `ecuisine_mess/test/features/email/email_service_test.dart`
  - [x] Create unit tests in `ecuisine_mess/test/features/email/smtp_settings_repository_test.dart`
  - [x] Run `flutter analyze` and verify 0 issues
  - [x] Run `flutter test` and verify all tests pass (104 tests green)
