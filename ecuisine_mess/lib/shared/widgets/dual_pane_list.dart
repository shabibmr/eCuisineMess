import 'package:flutter/material.dart';

class DualPaneList<T> extends StatefulWidget {
  const DualPaneList({
    super.key,
    required this.availableItems,
    required this.mappedItems,
    required this.itemId,
    required this.itemTitle,
    this.itemSubtitle,
    this.itemCategory,
    this.availableTrailing,
    this.mappedTrailing,
    required this.onAdd,
    required this.onRemove,
    this.onAddAll,
    this.onRemoveAll,
    this.availableTitle = 'Available Items',
    this.mappedTitle = 'Mapped Items',
    this.height = 450,
  });

  final List<T> availableItems;
  final List<T> mappedItems;
  final String Function(T item) itemId;
  final String Function(T item) itemTitle;
  final String Function(T item)? itemSubtitle;
  final String Function(T item)? itemCategory;
  final Widget Function(T item)? availableTrailing;
  final Widget Function(BuildContext context, T item, int index)? mappedTrailing;
  final ValueChanged<List<T>> onAdd;
  final ValueChanged<List<T>> onRemove;
  final VoidCallback? onAddAll;
  final VoidCallback? onRemoveAll;
  final String availableTitle;
  final String mappedTitle;
  final double height;

  @override
  State<DualPaneList<T>> createState() => _DualPaneListState<T>();
}

class _DualPaneListState<T> extends State<DualPaneList<T>> {
  final TextEditingController _availableSearchCtrl = TextEditingController();
  final TextEditingController _mappedSearchCtrl = TextEditingController();
  final Set<String> _selectedAvailableIds = {};
  final Set<String> _selectedMappedIds = {};
  String? _selectedCategory;

  @override
  void dispose() {
    _availableSearchCtrl.dispose() ;
    _mappedSearchCtrl.dispose();
    super.dispose();
  }

  List<T> _filterAvailable() {
    final query = _availableSearchCtrl.text.trim().toLowerCase();
    return widget.availableItems.where((item) {
      if (_selectedCategory != null &&
          widget.itemCategory != null &&
          widget.itemCategory!(item) != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      final title = widget.itemTitle(item).toLowerCase();
      final sub = widget.itemSubtitle?.call(item).toLowerCase() ?? '';
      return title.contains(query) || sub.contains(query);
    }).toList();
  }

  List<T> _filterMapped() {
    final query = _mappedSearchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return widget.mappedItems;
    return widget.mappedItems.where((item) {
      final title = widget.itemTitle(item).toLowerCase();
      final sub = widget.itemSubtitle?.call(item).toLowerCase() ?? '';
      return title.contains(query) || sub.contains(query);
    }).toList();
  }

  List<String> _getCategories() {
    if (widget.itemCategory == null) return [];
    final cats = <String>{};
    for (final it in widget.availableItems) {
      final cat = widget.itemCategory!(it);
      if (cat.isNotEmpty) cats.add(cat);
    }
    return cats.toList()..sort();
  }

  void _handleAddSelected() {
    final filtered = _filterAvailable();
    final toAdd = filtered
        .where((item) => _selectedAvailableIds.contains(widget.itemId(item)))
        .toList();
    if (toAdd.isNotEmpty) {
      widget.onAdd(toAdd);
      setState(() {
        _selectedAvailableIds.clear();
      });
    }
  }

  void _handleRemoveSelected() {
    final filtered = _filterMapped();
    final toRemove = filtered
        .where((item) => _selectedMappedIds.contains(widget.itemId(item)))
        .toList();
    if (toRemove.isNotEmpty) {
      widget.onRemove(toRemove);
      setState(() {
        _selectedMappedIds.clear();
      });
    }
  }

  void _handleAddAll() {
    if (widget.onAddAll != null) {
      widget.onAddAll!();
    } else {
      final filtered = _filterAvailable();
      if (filtered.isNotEmpty) {
        widget.onAdd(filtered);
      }
    }
    setState(() {
      _selectedAvailableIds.clear();
    });
  }

  void _handleRemoveAll() {
    if (widget.onRemoveAll != null) {
      widget.onRemoveAll!();
    } else {
      final filtered = _filterMapped();
      if (filtered.isNotEmpty) {
        widget.onRemove(filtered);
      }
    }
    setState(() {
      _selectedMappedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final available = _filterAvailable();
    final mapped = _filterMapped();
    final categories = _getCategories();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final availablePane = _buildPane(
          title: widget.availableTitle,
          count: widget.availableItems.length,
          filteredCount: available.length,
          searchCtrl: _availableSearchCtrl,
          searchHint: 'Search available items...',
          categoryFilter: categories.isNotEmpty
              ? DropdownButton<String?>(
                  value: _selectedCategory,
                  isDense: true,
                  hint: const Text('All Categories', style: TextStyle(fontSize: 12)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories', style: TextStyle(fontSize: 12)),
                    ),
                    ...categories.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                  },
                )
              : null,
          items: available,
          selectedIds: _selectedAvailableIds,
          onItemTap: (item) {
            final id = widget.itemId(item);
            setState(() {
              if (_selectedAvailableIds.contains(id)) {
                _selectedAvailableIds.remove(id);
              } else {
                _selectedAvailableIds.add(id);
              }
            });
          },
          onItemDoubleTap: (item) {
            widget.onAdd([item]);
            setState(() => _selectedAvailableIds.remove(widget.itemId(item)));
          },
          trailingBuilder: (item, index) =>
              widget.availableTrailing?.call(item) ??
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Add',
                onPressed: () {
                  widget.onAdd([item]);
                  setState(() => _selectedAvailableIds.remove(widget.itemId(item)));
                },
              ),
          selectAll: () {
            setState(() {
              _selectedAvailableIds.addAll(available.map(widget.itemId));
            });
          },
          clearSelection: () {
            setState(() {
              _selectedAvailableIds.clear();
            });
          },
        );

        final mappedPane = _buildPane(
          title: widget.mappedTitle,
          count: widget.mappedItems.length,
          filteredCount: mapped.length,
          searchCtrl: _mappedSearchCtrl,
          searchHint: 'Search mapped items...',
          items: mapped,
          selectedIds: _selectedMappedIds,
          onItemTap: (item) {
            final id = widget.itemId(item);
            setState(() {
              if (_selectedMappedIds.contains(id)) {
                _selectedMappedIds.remove(id);
              } else {
                _selectedMappedIds.add(id);
              }
            });
          },
          onItemDoubleTap: (item) {
            widget.onRemove([item]);
            setState(() => _selectedMappedIds.remove(widget.itemId(item)));
          },
          trailingBuilder: (item, index) {
            if (widget.mappedTrailing != null) {
              return widget.mappedTrailing!(context, item, index);
            }
            return IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
              tooltip: 'Remove',
              onPressed: () {
                widget.onRemove([item]);
                setState(() => _selectedMappedIds.remove(widget.itemId(item)));
              },
            );
          },
          selectAll: () {
            setState(() {
              _selectedMappedIds.addAll(mapped.map(widget.itemId));
            });
          },
          clearSelection: () {
            setState(() {
              _selectedMappedIds.clear();
            });
          },
        );

        final controls = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: isNarrow
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectedAvailableIds.isNotEmpty ? _handleAddSelected : null,
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      label: const Text('Add'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _selectedMappedIds.isNotEmpty ? _handleRemoveSelected : null,
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Remove'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _selectedAvailableIds.isNotEmpty ? _handleAddSelected : null,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _selectedMappedIds.isNotEmpty ? _handleRemoveSelected : null,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: available.isNotEmpty ? _handleAddAll : null,
                      style: OutlinedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const Icon(Icons.keyboard_double_arrow_right, size: 18),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: mapped.isNotEmpty ? _handleRemoveAll : null,
                      style: OutlinedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                      ),
                      child: const Icon(Icons.keyboard_double_arrow_left, size: 18),
                    ),
                  ],
                ),
        );

        if (isNarrow) {
          return Column(
            children: [
              SizedBox(height: widget.height / 2, child: availablePane),
              controls,
              SizedBox(height: widget.height / 2, child: mappedPane),
            ],
          );
        }

        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: availablePane),
              controls,
              Expanded(child: mappedPane),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPane({
    required String title,
    required int count,
    required int filteredCount,
    required TextEditingController searchCtrl,
    required String searchHint,
    Widget? categoryFilter,
    required List<T> items,
    required Set<String> selectedIds,
    required ValueChanged<T> onItemTap,
    required ValueChanged<T> onItemDoubleTap,
    required Widget Function(T item, int index) trailingBuilder,
    required VoidCallback selectAll,
    required VoidCallback clearSelection,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search + Category filter
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: searchHint,
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (categoryFilter != null) ...[
                  const SizedBox(width: 8),
                  categoryFilter,
                ],
              ],
            ),
          ),
          // Sub-bar: selection actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedIds.isEmpty
                      ? '$filteredCount items'
                      : '${selectedIds.length} of $filteredCount selected',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: items.isEmpty ? null : selectAll,
                      child: const Text('Select All', style: TextStyle(fontSize: 11)),
                    ),
                    if (selectedIds.isNotEmpty)
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: clearSelection,
                        child: const Text('Clear', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No items',
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final id = widget.itemId(item);
                      final isSelected = selectedIds.contains(id);

                      return InkWell(
                        onTap: () => onItemTap(item),
                        onDoubleTap: () => onItemDoubleTap(item),
                        child: Container(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                              : null,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                visualDensity: VisualDensity.compact,
                                onChanged: (_) => onItemTap(item),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.itemTitle(item),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.itemSubtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.itemSubtitle!(item),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailingBuilder(item, index),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
