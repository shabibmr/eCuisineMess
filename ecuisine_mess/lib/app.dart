import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_router.dart';
import 'package:ecuisine_mess/core/theme/app_theme.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/email/data/datasources/smtp_firestore_datasource.dart';
import 'package:ecuisine_mess/features/email/data/repositories/smtp_settings_repository_impl.dart';
import 'package:ecuisine_mess/features/email/data/services/mailer_email_service_impl.dart';
import 'package:ecuisine_mess/features/email/domain/repositories/smtp_settings_repository.dart';
import 'package:ecuisine_mess/features/email/domain/services/email_service.dart';
import 'package:ecuisine_mess/features/email/presentation/bloc/email_bloc.dart';
import 'package:ecuisine_mess/features/email/presentation/cubit/smtp_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ECuisineMessApp extends StatelessWidget {
  const ECuisineMessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SmtpSettingsRepository>(
          create: (_) => SmtpSettingsRepositoryImpl(
            firestoreDataSource: SmtpFirestoreDataSourceImpl(),
            prefs: sl<SharedPreferences>(),
          ),
        ),
        RepositoryProvider<EmailService>(
          create: (context) => MailerEmailServiceImpl(
            settingsRepository: context.read<SmtpSettingsRepository>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
          BlocProvider<EmailBloc>(
            create: (context) => EmailBloc(
              emailService: context.read<EmailService>(),
            ),
          ),
          BlocProvider<SmtpSettingsCubit>(
            create: (context) => SmtpSettingsCubit(
              repository: context.read<SmtpSettingsRepository>(),
              emailService: context.read<EmailService>(),
            )..loadSettings(),
          ),
        ],
        child: MaterialApp.router(
          title: 'eCuisine Mess Module',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: sl<AppRouter>().config,
          builder: (context, child) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthUnknown) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return child ?? const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
