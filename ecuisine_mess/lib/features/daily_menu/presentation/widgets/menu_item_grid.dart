import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:flutter/material.dart';

/// Item table + mapped-item picker for the active cuisine×meal slot.
class MenuItemGrid extends StatelessWidget {
  const MenuItemGrid({
    super.key,
    required this.items,
    required this.availableMappedItems,
    required this.readOnly,
    required this.hasMappedItems,
    required this.cuisineName,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onQtyChanged,
    this.onOpenCuisineEditor,
  });

  final List<MenuSlotLine> items;
  final List<CuisineItemMapping> availableMappedItems;
  final bool readOnly;
  final bool hasMappedItems;
  final String cuisineName;
  final ValueChanged<String> onAddItem;
  final ValueChanged<String> onRemoveItem;
  final void Function(String itemId, double quantity) onQtyChanged;
  final VoidCallback? onOpenCuisineEditor;

  @override
  Widget build(BuildContext context) {
    if (!hasMappedItems) {
      return _UnmappedEmpty(
        cuisineName: cuisineName,
        onOpenCuisineEditor: onOpenCuisineEditor,
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No items in this meal yet. Click Add All Mapped or choose items below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.hintColor, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final line = items[index];
                    return _MenuItemRow(
                      index: index + 1,
                      line: line,
                      readOnly: readOnly,
                      onQtyChanged: (qty) => onQtyChanged(line.itemId, qty),
                      onRemove: () => onRemoveItem(line.itemId),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'add-${availableMappedItems.map((e) => e.itemId).join(',')}',
          ),
          initialValue: null,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: '+ Add item from mapped items…',
          ),
          items: availableMappedItems
              .map(
                (m) => DropdownMenuItem(
                  value: m.itemId,
                  child: Text(
                    '${m.itemName}'
                    '${m.category != null && m.category!.isNotEmpty ? ' (${m.category} · ${m.unit})' : ' (${m.unit})'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: readOnly || availableMappedItems.isEmpty
              ? null
              : (id) {
                  if (id == null) return;
                  onAddItem(id);
                },
        ),
      ],
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.index,
    required this.line,
    required this.readOnly,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final int index;
  final MenuSlotLine line;
  final bool readOnly;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onRemove;

  static const double minQuantity = 1;

  double get _quantity => line.quantity < minQuantity ? minQuantity : line.quantity;

  static String _formatQty(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  void _step(double delta) {
    final next = _quantity + delta;
    if (next < minQuantity) return;
    onQtyChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrease = !readOnly && _quantity > minQuantity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.itemName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (line.category != null && line.category!.isNotEmpty)
                  Text(
                    line.category!,
                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decrease quantity',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: canDecrease ? () => _step(-1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(
            width: 28,
            child: Text(
              _formatQty(_quantity),
              key: ValueKey('menu-line-qty-${line.itemId}'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: readOnly ? null : () => _step(1),
            icon: const Icon(Icons.add, size: 18),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              line.unit,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: readOnly ? null : onRemove,
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _UnmappedEmpty extends StatelessWidget {
  const _UnmappedEmpty({
    required this.cuisineName,
    this.onOpenCuisineEditor,
  });

  final String cuisineName;
  final VoidCallback? onOpenCuisineEditor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_outlined, size: 44, color: theme.hintColor),
            const SizedBox(height: 12),
            const Text(
              'No items mapped to this cuisine yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Open the Cuisine Editor to map dishes before creating daily menus.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.hintColor),
            ),
            if (onOpenCuisineEditor != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onOpenCuisineEditor,
                child: Text('Open $cuisineName'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
