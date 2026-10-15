import 'package:flutter/material.dart';

enum UserAccountMenuAction {
  organizations,
  mealTimes,
  itemCategories,
  smtp,
  updates,
  printer,
  server,
  logout,
}

/// Account chip that opens Administrator pages, settings, and logout.
class UserAccountMenu extends StatelessWidget {
  const UserAccountMenu({
    super.key,
    required this.displayName,
    required this.onSelected,
  });

  final String displayName;
  final ValueChanged<UserAccountMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<UserAccountMenuAction>(
      tooltip: displayName,
      offset: const Offset(0, 8),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<UserAccountMenuAction>(
          enabled: false,
          height: 32,
          child: Text(
            'ADMINISTRATOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const PopupMenuItem(
          value: UserAccountMenuAction.organizations,
          child: _MenuRow(
            icon: Icons.business_outlined,
            label: 'Organization',
          ),
        ),
        const PopupMenuItem(
          value: UserAccountMenuAction.mealTimes,
          child: _MenuRow(
            icon: Icons.schedule_outlined,
            label: 'Meal Times',
          ),
        ),
        const PopupMenuItem(
          value: UserAccountMenuAction.itemCategories,
          child: _MenuRow(
            icon: Icons.category_outlined,
            label: 'Item Categories',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: UserAccountMenuAction.smtp,
          child: _MenuRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email & SMTP Settings',
          ),
        ),
        const PopupMenuItem(
          value: UserAccountMenuAction.updates,
          child: _MenuRow(
            icon: Icons.system_update_alt_rounded,
            label: 'Check for Updates',
          ),
        ),
        const PopupMenuItem(
          value: UserAccountMenuAction.printer,
          child: _MenuRow(
            icon: Icons.print_outlined,
            label: 'Printer Settings',
          ),
        ),
        const PopupMenuItem(
          value: UserAccountMenuAction.server,
          child: _MenuRow(
            icon: Icons.cloud_outlined,
            label: 'Server Connection',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: UserAccountMenuAction.logout,
          child: _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: scheme.error,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? IconTheme.of(context).color;
    return Row(
      children: [
        Icon(icon, size: 20, color: effective),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
