import 'dart:async';

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/router/nav_destinations.dart';
import 'package:ecuisine_mess/core/services/app_update_service.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/email/presentation/widgets/smtp_settings_dialog.dart';
import 'package:ecuisine_mess/features/settings/presentation/widgets/printer_settings_dialog.dart';
import 'package:ecuisine_mess/features/settings/presentation/widgets/server_settings_dialog.dart';
import 'package:ecuisine_mess/features/update/presentation/update_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/layout/animated_nav_icon.dart';
import 'package:ecuisine_mess/shared/widgets/layout/user_account_menu.dart';
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final name =
                    state is Authenticated ? state.user.displayName : 'User';
                return UserAccountMenu(
                  displayName: name,
                  onSelected: (action) => _onAccountAction(context, action),
                );
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: railIndexForBranch(
              widget.navigationShell.currentIndex,
            ),
            onDestinationSelected: (index) {
              widget.navigationShell.goBranch(branchIndexForRail(index));
            },
            scrollable: true,
            destinations: [
              for (final dest in kRailDestinations)
                NavigationRailDestination(
                  icon: AnimatedNavIcon(
                    icon: dest.icon,
                    isSelected: false,
                  ),
                  selectedIcon: AnimatedNavIcon(
                    icon: dest.selectedIcon ?? dest.icon,
                    isSelected: true,
                  ),
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

  void _onAccountAction(BuildContext context, UserAccountMenuAction action) {
    switch (action) {
      case UserAccountMenuAction.organizations:
        context.goNamed(AppRoutes.organizations.name);
      case UserAccountMenuAction.smtp:
        showSmtpSettingsDialog(context);
      case UserAccountMenuAction.updates:
        unawaited(_checkForUpdates(manual: true));
      case UserAccountMenuAction.printer:
        showPrinterSettingsDialog(context);
      case UserAccountMenuAction.server:
        showServerSettingsDialog(context);
      case UserAccountMenuAction.logout:
        context.read<AuthBloc>().add(const LogoutRequested());
    }
  }
}
