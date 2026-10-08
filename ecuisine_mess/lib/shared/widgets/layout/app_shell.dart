import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/nav_destinations.dart';
import 'package:ecuisine_mess/core/services/app_update_service.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
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
          ),
        );
      }
    } catch (e) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check for updates: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(9),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo_dark.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.restaurant_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('eCuisine'),
                Text(
                  'MESS MANAGEMENT',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name =
                  state is Authenticated ? state.user.displayName : 'User';
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.person_outline,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _Action(
            tooltip: 'Email & SMTP Settings',
            icon: Icons.mail_outline_rounded,
            onPressed: () => showSmtpSettingsDialog(context),
          ),
          _Action(
            tooltip: 'Check for Updates',
            icon: Icons.system_update_alt_rounded,
            onPressed: () => _checkForUpdates(manual: true),
          ),
          _Action(
            tooltip: 'Printer Settings',
            icon: Icons.print_outlined,
            onPressed: () => showPrinterSettingsDialog(context),
          ),
          _Action(
            tooltip: 'Server Connection',
            icon: Icons.cloud_outlined,
            onPressed: () => showServerSettingsDialog(context),
          ),
          _Action(
            tooltip: 'Logout',
            icon: Icons.logout_rounded,
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: widget.navigationShell.goBranch,
            scrollable: true,
            destinations: [
              for (final dest in kNavDestinations)
                NavigationRailDestination(
                  icon: Icon(dest.icon),
                  selectedIcon: Icon(dest.icon),
                  label: Text(dest.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: scheme.outlineVariant,
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}
