import 'package:ecuisine_mess/shared/widgets/feedback/app_alert_banner.dart';
import 'package:flutter/material.dart';

/// Past-date read-only banner (mock-ui past-date-banner).
class MenuPastDateBanner extends StatelessWidget {
  const MenuPastDateBanner({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AppAlertBanner.info(
      visible: visible,
      icon: Icons.info_outline,
      message: 'History – Read Only. Past dates cannot be modified.',
    );
  }
}

/// Meal locked because bills already issued (mock-ui meal-locked-banner).
class MenuMealLockedBanner extends StatelessWidget {
  const MenuMealLockedBanner({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AppAlertBanner.warning(
      visible: visible,
      icon: Icons.lock_outline,
      message:
          'This meal is locked because bills have already been issued on this date.',
    );
  }
}
