import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/nav_destinations.dart';
import 'package:ecuisine_mess/core/services/app_update_service.dart';
import 'package:ecuisine_mess/core/theme/app_theme.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/email/presentation/widgets/smtp_settings_dialog.dart';
import 'package:ecuisine_mess/features/settings/presentation/widgets/printer_settings_dialog.dart';
import 'package:ecuisine_mess/features/settings/presentation/widgets/server_settings_dialog.dart';
import 'package:ecuisine_mess/features/update/presentation/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates(manual: false);
    });
  }

  Future<void> _checkForUpdates({bool manual = false}) async {
    try {
      if (!sl.isRegistered<AppUpdateService>()) return;
      final updateService = sl<AppUpdateService>();
      final result = await updateService.checkForUpdate();
      if (!mounted) return;

      if (result.hasUpdate) {
        await UpdateDialog.show(
          context,
          checkResult: result,
          updateService: updateService,
        );
      } else if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage != null
                  ? 'Update check failed: ${result.errorMessage}'
                  : 'eCuisine is up to date (v${result.currentVersion})',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo_dark.jpg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'eCuisine Mess Billing & Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name =
                  state is Authenticated ? state.user.displayName : '';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.email_outlined),
            tooltip: 'Email & SMTP Settings',
            onPressed: () => showSmtpSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.system_update_alt_outlined),
            tooltip: 'Check for Updates',
            onPressed: () => _checkForUpdates(manual: true),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Printer Settings',
            onPressed: () => showPrinterSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Connection Settings',
            onPressed: () => showServerSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: widget.navigationShell.goBranch,
            labelType: NavigationRailLabelType.all,
            scrollable: true,
            backgroundColor: AppTheme.primary,
            selectedIconTheme: const IconThemeData(color: Colors.amber),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            destinations: [
              for (final dest in kNavDestinations)
                NavigationRailDestination(
                  icon: Icon(dest.icon),
                  label: Text(dest.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}
