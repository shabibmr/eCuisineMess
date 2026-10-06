import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_router.dart';
import 'package:ecuisine_mess/core/theme/app_theme.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ECuisineMessApp extends StatelessWidget {
  const ECuisineMessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
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
    );
  }
}
