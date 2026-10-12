import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/app_alert_banner.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          LoginSubmitted(
            username: _userCtrl.text.trim(),
            password: _passCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final busy = state is AuthLoginInProgress;
        final error = state is Unauthenticated
            ? state.message
            : state is AuthLoginInProgress
                ? state.previousMessage
                : null;

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter username' : null,
              ),
              const SizedBox(height: 16),
              AppPasswordField(
                controller: _passCtrl,
                label: 'Password',
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter password' : null,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                AppAlertBanner.error(message: error),
              ],
              const SizedBox(height: 20),
              AppSaveButton(
                label: 'Sign in',
                loadingLabel: 'Signing in...',
                isLoading: busy,
                isFullWidth: true,
                icon: null,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
