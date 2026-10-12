import 'package:flutter/material.dart';

/// Form field with built-in password visibility toggle icon.
///
/// Complies with Material 3 InputDecorator styling and includes:
/// - Eye / Eye-off icon suffix toggling obscured text.
/// - Standard lock prefix icon.
/// - Validation support, keyboard submit callbacks, and autofocus.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.initialValue,
    this.label = 'Password',
    this.hintText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon = Icons.lock_outline,
    this.autofocus = false,
    this.enabled = true,
  });

  /// Optional external controller.
  final TextEditingController? controller;

  /// Initial value when not providing an external controller.
  final String? initialValue;

  /// Label for the field. Defaults to 'Password'.
  final String label;

  /// Placeholder hint text.
  final String? hintText;

  /// Validator callback.
  final FormFieldValidator<String>? validator;

  /// Callback when text value changes.
  final ValueChanged<String>? onChanged;

  /// Callback when submitted from keyboard.
  final ValueChanged<String>? onFieldSubmitted;

  /// Prefix icon for decoration.
  final IconData? prefixIcon;

  /// Whether the field focuses automatically.
  final bool autofocus;

  /// Whether the field is enabled.
  final bool enabled;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      obscureText: _obscure,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        isDense: true,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 18)
            : null,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscure ? Icons.visibility : Icons.visibility_off,
            size: 18,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
