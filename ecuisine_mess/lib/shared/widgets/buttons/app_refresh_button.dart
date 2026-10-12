import 'package:flutter/material.dart';

/// Standard standardized `IconButton` with a refresh icon, tooltip, and optional rotation/loading state.
class AppRefreshButton extends StatelessWidget {
  const AppRefreshButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Refresh',
    this.isLoading = false,
  });

  /// Callback executed when tapping the refresh button.
  final VoidCallback? onPressed;

  /// Tooltip text. Defaults to 'Refresh'.
  final String tooltip;

  /// Whether a refresh is currently pending/in progress.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return IconButton(
      tooltip: tooltip,
      icon: const Icon(Icons.refresh),
      onPressed: onPressed,
    );
  }
}
