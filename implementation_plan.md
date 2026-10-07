# Implementation Plan — Email Service Module (Flutter BLoC DI + Firestore Client)

## 1. Feature Summary
Implementation of an asynchronous, client-side **Email Service Module** in the Flutter app (`ecuisine_mess`) capable of sending emails with attachments (pipe-delimited CSV reports, PDFs, or arbitrary files) from anywhere in the application.

### Key Architectural Constraints
1. **NO GetIt**: Dependency injection is handled purely via **`flutter_bloc`** (`RepositoryProvider` and `BlocProvider` at the app root).
2. **Direct Firestore Client**: SMTP settings are stored in Cloud Firestore (document `settings/smtp`) and fetched directly by the Flutter client (with local `SharedPreferences` cache fallback), without needing MariaDB or backend API endpoints for SMTP config.
3. **Callable from Anywhere**: Accessible via `context.read<EmailService>()`, `context.read<EmailBloc>()`, or `EmailService.current` static accessor for non-UI contexts.
4. **Asynchronous & Non-Blocking**: Dispatched in the background using `package:mailer` so the UI remains fluid.

---

## 2. Architecture & DI Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                        App Root (app.dart)                             │
│                                                                        │
│  MultiRepositoryProvider (flutter_bloc DI)                             │
│  ├── RepositoryProvider<SmtpSettingsRepository>                        │
│  │     └── SmtpSettingsRepositoryImpl                                  │
│  │           ├── SmtpFirestoreDataSource (Direct Firestore Client)     │
│  │           └── SharedPreferences (Local Cache)                       │
│  └── RepositoryProvider<EmailService>                                  │
│        └── MailerEmailServiceImpl(settingsRepository: ...)             │
│                                                                        │
│  MultiBlocProvider                                                     │
│  ├── BlocProvider<AuthBloc>                                            │
│  ├── BlocProvider<EmailBloc>                                           │
│  └── BlocProvider<SmtpSettingsCubit>                                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  Client-Side Firestore Integration                     │
│                                                                        │
│  Flutter Client (Dio) ──► Cloud Firestore REST API                     │
│                          GET/PATCH /projects/{id}/databases/           │
│                                    (default)/documents/settings/smtp   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      Email Sending (package:mailer)                    │
│                                                                        │
│  EmailService.sendEmail(...) / sendReportEmail(...)                    │
│  ├── Asynchronous SMTP transport (SSL / STARTTLS)                      │
│  ├── In-memory bytes (fresh pipe-delimited CSVs) or file attachments   │
│  └── Rich HTML email templates for daily/shift reports                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Components & File Breakdown

### Layer 1: Configuration & Dependencies
- `[MODIFY]` `ecuisine_mess/pubspec.yaml`
  - Add `mailer: ^7.2.0` (SMTP client library). Note: `dio: ^5.11.1` and `flutter_bloc: ^9.1.1` are already in dependencies.
- `[MODIFY]` `ecuisine_mess/lib/core/config/constants.dart`
  - Add Firestore constants:
    - `defaultFirebaseProjectId`: Project ID (configurable).
    - `firestoreSmtpDocPath`: `'settings/smtp'`.
    - `smtpSettingsCachePrefsKey`: `'mess_smtp_settings_cache'`.

### Layer 2: Email Domain & Core Service
- `[NEW]` `ecuisine_mess/lib/features/email/domain/entities/email_attachment.dart`
  - Holds attachment payload: supports in-memory bytes (`List<int>? bytes`) or local file path (`String? filePath`), `fileName`, and `mimeType` (e.g., `text/csv`, `application/pdf`).
- `[NEW]` `ecuisine_mess/lib/features/email/domain/entities/email_send_result.dart`
  - Result status: `bool success`, `String? messageId`, `String? errorMessage`.
- `[NEW]` `ecuisine_mess/lib/features/email/domain/services/email_service.dart`
  - Abstract interface:
    - `Future<EmailSendResult> sendEmail(...)`
    - `Future<EmailSendResult> sendReportEmail(...)`
    - `Future<EmailSendResult> testConnection(...)`
    - `static EmailService get current`: static singleton accessor populated on startup so non-widget code or utilities can trigger emails directly.
- `[NEW]` `ecuisine_mess/lib/features/email/data/services/mailer_email_service_impl.dart`
  - Implementation using `package:mailer`.
  - Non-blocking asynchronous dispatch with timeout and detailed logger.
  - Converts `EmailAttachment` into `StreamAttachment` or `FileAttachment`.
  - Professional HTML template generator for eCuisine Mess automated reports.

### Layer 3: Firestore Settings Data Layer
- `[NEW]` `ecuisine_mess/lib/features/email/domain/entities/smtp_settings.dart`
  - Entity holding: `host`, `port`, `username`, `password`, `fromEmail`, `fromName`, `useTls`, `useSsl`, `supervisorEmails` (`List<String>`), and `updatedAt`.
- `[NEW]` `ecuisine_mess/lib/features/email/data/models/smtp_settings_model.dart`
  - JSON and Firestore Document Map converter (supports Firestore REST format `{"fields": {...}}` and standard JSON).
- `[NEW]` `ecuisine_mess/lib/features/email/data/datasources/smtp_firestore_datasource.dart`
  - Direct client Firestore access via Dio REST API:
    - `GET` document `settings/smtp` directly from Firestore.
    - `PATCH` document `settings/smtp` to save settings back from client.
- `[NEW]` `ecuisine_mess/lib/features/email/domain/repositories/smtp_settings_repository.dart`
  - Repository interface for retrieving and saving settings.
- `[NEW]` `ecuisine_mess/lib/features/email/data/repositories/smtp_settings_repository_impl.dart`
  - Implements repository: fetches from Firestore, caches in `SharedPreferences`, and falls back to cached settings if offline.

### Layer 4: BLoC / Cubit State Management (flutter_bloc DI)
- `[NEW]` `ecuisine_mess/lib/features/email/presentation/bloc/email_bloc.dart`
  - Events: `SendEmailEvent`, `SendReportEmailEvent`.
  - States: `EmailInitial`, `EmailSending`, `EmailSentSuccess`, `EmailFailure`.
- `[NEW]` `ecuisine_mess/lib/features/email/presentation/cubit/smtp_settings_cubit.dart`
  - Manages SMTP settings form, loading from Firestore, saving, and testing connection.
- `[MODIFY]` `ecuisine_mess/lib/app.dart`
  - Wrap app in `MultiRepositoryProvider` providing `SmtpSettingsRepository` and `EmailService`.
  - Provide `EmailBloc` and `SmtpSettingsCubit` in `MultiBlocProvider`.
  - **Zero GetIt usage for this feature.**

### Layer 5: UI Presentation
- `[NEW]` `ecuisine_mess/lib/features/email/presentation/widgets/smtp_settings_dialog.dart`
  - Dialog for viewing/editing SMTP host, port, credentials, TLS/SSL, supervisor emails, and "Test Connection".
- `[MODIFY]` `ecuisine_mess/lib/shared/widgets/layout/app_shell.dart`
  - Add Email icon button (`Icons.email_outlined`) in app bar header next to printer and server settings.
- `[NEW]` `ecuisine_mess/lib/features/reports/presentation/widgets/email_report_dialog.dart`
  - Dialog to confirm supervisor recipient(s), add optional note, and trigger email send with attached pipe-delimited CSV.
- `[MODIFY]` `ecuisine_mess/lib/features/reports/presentation/widgets/report_tab.dart`
  - Add "Email Report" action button alongside "Export CSV".

### Layer 6: Tests & Verification
- `[NEW]` `ecuisine_mess/test/features/email/email_service_test.dart`
  - Unit tests for attachments, result models, and service contract.
- `[NEW]` `ecuisine_mess/test/features/email/smtp_settings_repository_test.dart`
  - Unit tests for Firestore document parsing, cache fallback, and repository error handling.
- Verification commands:
  - `flutter analyze` (ensure 0 issues)
  - `flutter test` (ensure all tests pass)

---

## 4. Exit Criteria
1. `EmailService` and `SmtpSettingsRepository` are provided via `flutter_bloc`'s `RepositoryProvider` (no `GetIt`).
2. SMTP settings are fetched directly from Cloud Firestore by the client, with local offline cache fallback.
3. Automated reports can be emailed with attached pipe-delimited CSV files to supervisor emails asynchronously.
4. `flutter analyze` reports zero warnings/errors, and test suite is green.
