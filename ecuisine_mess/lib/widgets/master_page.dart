import 'package:flutter/material.dart';

/// Shared chrome for master list screens: title, actions, loading / error / empty / child.
class MasterPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? toolbar;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;

  const MasterPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.toolbar,
    this.loading = false,
    this.error,
    this.onRetry,
    this.isEmpty = false,
    this.emptyMessage = 'No records found',
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              ...?actions,
            ],
          ),
          if (toolbar != null) ...[
            const SizedBox(height: 16),
            toolbar!,
          ],
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }
    if (isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return child;
  }
}
