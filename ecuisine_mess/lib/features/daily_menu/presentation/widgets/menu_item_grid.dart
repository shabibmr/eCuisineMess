import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _MenuItemRow extends StatefulWidget {
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

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: _formatQty(widget.line.quantity),
    );
  }

  @override
  void didUpdateWidget(covariant _MenuItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.itemId != widget.line.itemId ||
        oldWidget.line.quantity != widget.line.quantity) {
      final next = _formatQty(widget.line.quantity);
      if (_qtyCtrl.text != next) {
        _qtyCtrl.text = next;
      }
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  static String _formatQty(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${widget.index}',
              style: TextStyle(fontSize: 11, color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.line.itemName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.line.category != null &&
                    widget.line.category!.isNotEmpty)
                  Text(
                    widget.line.category!,
                    style: TextStyle(fontSize: 11, color: theme.hintColor),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _qtyCtrl,
              enabled: !widget.readOnly,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (raw) {
                final qty = double.tryParse(raw.trim());
                if (qty == null || qty <= 0) return;
                widget.onQtyChanged(qty);
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              widget.line.unit,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: widget.readOnly ? null : widget.onRemove,
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
