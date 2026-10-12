import 'package:flutter/material.dart';

/// An item descriptor for [AppDropdown].
class AppDropdownItem<T> {
  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Generic, Material 3 compliant wrapper around [DropdownButtonFormField<T>].
///
/// Features:
/// - Supports optional placeholder/unselected entry (`All`, `Select...`, etc.).
/// - Clean label decoration, density, and validation support.
/// - Optional leading icon per item or prefix icon for the whole field.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.placeholderLabel,
    this.validator,
    this.enabled = true,
    this.isExpanded = true,
    this.width,
  });

  /// The list of options.
  final List<AppDropdownItem<T>> items;

  /// The currently selected value (or null).
  final T? value;

  /// Callback when an item is selected.
  final ValueChanged<T?>? onChanged;

  /// Form field label text.
  final String? label;

  /// Placeholder hint text when nothing is selected.
  final String? hintText;

  /// Prefix icon for the decoration.
  final IconData? prefixIcon;

  /// If non-null, inserts a null-value entry at the top with this label (e.g. "All cuisines", "Select...").
  final String? placeholderLabel;

  /// Form validation callback.
  final FormFieldValidator<T?>? validator;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the dropdown menu expands to fill width.
  final bool isExpanded;

  /// Optional explicit width constraint.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final dropdownItems = <DropdownMenuItem<T?>>[];

    if (placeholderLabel != null) {
      dropdownItems.add(
        DropdownMenuItem<T?>(
          value: null,
          child: Text(
            placeholderLabel!,
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }

    for (final item in items) {
      dropdownItems.add(
        DropdownMenuItem<T?>(
          value: item.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final field = DropdownButtonFormField<T?>(
      initialValue: value,
      items: dropdownItems,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        isDense: true,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: field,
      );
    }

    return field;
  }
}
