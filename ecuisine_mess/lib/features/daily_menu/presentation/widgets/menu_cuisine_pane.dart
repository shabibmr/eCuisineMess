import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:flutter/material.dart';

/// Left cuisine list with FULL/PARTIAL/EMPTY readiness pips.
class MenuCuisinePane extends StatelessWidget {
  const MenuCuisinePane({
    super.key,
    required this.cuisines,
    required this.readiness,
    required this.selectedCuisineId,
    required this.onSelected,
  });

  final List<CuisineOption> cuisines;
  final List<CuisineMenuStatus> readiness;
  final String? selectedCuisineId;
  final ValueChanged<String> onSelected;

  CuisineMenuStatus? _statusFor(String cuisineId) {
    for (final r in readiness) {
      if (r.cuisineId == cuisineId) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Text(
                  'CUISINES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cuisines.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              itemCount: cuisines.length,
              itemBuilder: (context, index) {
                final cuisine = cuisines[index];
                final selected = cuisine.id == selectedCuisineId;
                final status = _statusFor(cuisine.id);
                return _CuisineNavTile(
                  name: cuisine.name,
                  selected: selected,
                  fillStatus: status?.status ?? MenuFillStatus.empty,
                  onTap: () => onSelected(cuisine.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CuisineNavTile extends StatelessWidget {
  const _CuisineNavTile({
    required this.name,
    required this.selected,
    required this.fillStatus,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final MenuFillStatus fillStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (pip, color) = switch (fillStatus) {
      MenuFillStatus.full => ('✔', scheme.primary),
      MenuFillStatus.partial => ('◐', Colors.orange.shade700),
      MenuFillStatus.empty => ('○', scheme.outline),
    };

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Text(
                  pip,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
