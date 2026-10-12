import 'dart:async';
import 'package:flutter/material.dart';

/// Reusable search input field with search prefix icon, clear button suffix,
/// and optional debounced input callbacks.
///
/// Complies with Material 3 styling and supports both managed (internal controller)
/// and controlled (external controller) patterns.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.debounceDuration = Duration.zero,
    this.width,
    this.height,
    this.autofocus = false,
  });

  /// Optional external controller. If omitted, an internal controller is managed.
  final TextEditingController? controller;

  /// Initial text value when not supplying an external controller.
  final String? initialValue;

  /// Placeholder hint text.
  final String hintText;

  /// Called whenever text changes (subject to [debounceDuration]).
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard submit action is triggered.
  final ValueChanged<String>? onSubmitted;

  /// Called when the clear ('x') suffix icon is pressed.
  final VoidCallback? onCleared;

  /// Optional debounce duration before firing [onChanged]. Defaults to [Duration.zero].
  final Duration debounceDuration;

  /// Optional explicit width constraint.
  final double? width;

  /// Optional explicit height constraint.
  final double? height;

  /// Whether this field should focus automatically.
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _effectiveController;
  Timer? _debounceTimer;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _effectiveController = TextEditingController(text: widget.initialValue ?? '');
      _isInternalController = true;
    }
    _effectiveController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isInternalController) {
        _effectiveController.removeListener(_onTextChanged);
        _effectiveController.dispose();
      }
      if (widget.controller != null) {
        _effectiveController = widget.controller!;
        _isInternalController = false;
      } else {
        _effectiveController = TextEditingController(text: widget.initialValue ?? '');
        _isInternalController = true;
      }
      _effectiveController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _effectiveController.removeListener(_onTextChanged);
    if (_isInternalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    // Rebuild to toggle clear suffix button visibility
    setState(() {});
  }

  void _handleChanged(String value) {
    if (widget.debounceDuration == Duration.zero) {
      widget.onChanged?.call(value);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        widget.onChanged?.call(value);
      }
    });
  }

  void _handleClear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _effectiveController.text.isNotEmpty;

    final field = TextField(
      controller: _effectiveController,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: _handleChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear, size: 16),
                onPressed: _handleClear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: field,
      );
    }

    return field;
  }
}
