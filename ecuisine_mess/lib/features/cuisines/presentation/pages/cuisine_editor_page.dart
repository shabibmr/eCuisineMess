import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/bloc/cuisine_editor_bloc.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/dual_pane_list.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/app_alert_banner.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CuisineEditorPage extends StatelessWidget {
  const CuisineEditorPage({
    super.key,
    this.cuisineId,
  });

  final String? cuisineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CuisineEditorBloc>()
        ..add(CuisineEditorStarted(cuisineId: cuisineId)),
      child: const _CuisineEditorView(),
    );
  }
}

class _CuisineEditorView extends StatefulWidget {
  const _CuisineEditorView();

  @override
  State<_CuisineEditorView> createState() => _CuisineEditorViewState();
}

class _CuisineEditorViewState extends State<_CuisineEditorView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCopyCuisineId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showUnmapConflictDialog(
    BuildContext context,
    String message,
    Map<String, dynamic>? details,
  ) {
    final affectedItems = (details?['affected_items'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final affectedDates = (details?['affected_dates'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
            SizedBox(width: 8),
            Text('Cannot Unmap Scheduled Items'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 14),
              if (affectedItems.isNotEmpty) ...[
                const Text(
                  'Items actively used:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: affectedItems
                      .map((item) => Chip(
                            label: Text(item, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.red.shade50,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (affectedDates.isNotEmpty) ...[
                const Text(
                  'Scheduled menu dates:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  affectedDates.join(', '),
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                'Please remove these items from future daily menus before removing them from this cuisine mapping.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<CuisineEditorBloc>()
                  .add(const CuisineEditorDismissConflict());
            },
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CuisineEditorBloc, CuisineEditorState>(
      listener: (context, state) {
        if (_nameCtrl.text != state.name &&
            state.status == Status.success &&
            _nameCtrl.text.isEmpty) {
          _nameCtrl.text = state.name;
        }
        if (_descCtrl.text != state.description &&
            state.status == Status.success &&
            _descCtrl.text.isEmpty) {
          _descCtrl.text = state.description;
        }

        if (state.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.savedMessage ?? 'Cuisine saved successfully'),
              backgroundColor: Colors.green.shade800,
            ),
          );
          Navigator.of(context).pop(true);
        }

        if (state.unmapConflictMessage != null) {
          _showUnmapConflictDialog(
            context,
            state.unmapConflictMessage!,
            state.unmapConflictDetails,
          );
        } else if (state.error != null && !state.isSaving) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<CuisineEditorBloc>();

        if (state.status == Status.loading && state.availableItems.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isNew = state.isNew;
        final title = isNew ? 'New Cuisine' : 'Edit Cuisine: ${state.name}';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              AppSaveButton(
                label: 'Save Cuisine',
                isLoading: state.isSaving,
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    bloc.add(const CuisineEditorSubmitted());
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Metadata Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cuisine Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Cuisine Name *',
                                  hintText: 'e.g. North Indian, South Indian, Arabic',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Cuisine name is required';
                                  }
                                  return null;
                                },
                                onChanged: (val) =>
                                    bloc.add(CuisineEditorNameChanged(val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _descCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  hintText: 'Optional dietary notes or package details',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) =>
                                    bloc.add(CuisineEditorDescriptionChanged(val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 160,
                              child: AppSwitchTile(
                                title: 'Active',
                                value: state.isActive,
                                onChanged: (val) =>
                                    bloc.add(CuisineEditorActiveToggled(val)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Copy Mapping Bar
                if (state.otherCuisines.isNotEmpty) ...[
                  Card(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 20, color: Colors.blue.shade800),
                          const SizedBox(width: 10),
                          const Text(
                            'Copy Items from Existing Cuisine:',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AppDropdown<String>(
                              key: ValueKey(
                                'copy-cuisine-$_selectedCopyCuisineId',
                              ),
                              value: _selectedCopyCuisineId,
                              placeholderLabel: 'Select source cuisine...',
                              items: state.otherCuisines
                                  .map(
                                    (c) => AppDropdownItem<String>(
                                      value: c.id,
                                      label:
                                          '${c.cuisineName} (${c.mappedItemsCount} items)',
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedCopyCuisineId = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _selectedCopyCuisineId != null
                                ? () {
                                    bloc.add(
                                      CuisineEditorCopyMappingRequested(
                                        _selectedCopyCuisineId!,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Merge Items'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Empty warning banner
                if (state.hasUnsavedWarning) ...[
                  const AppAlertBanner.warning(
                    message:
                        'No items mapped yet. Members assigned to this cuisine will not have entitlement items until menu items are mapped.',
                  ),
                  const SizedBox(height: 16),
                ],

                // Dual Pane Mapping Container
                Text(
                  'Menu Items Entitlement Mapping',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Move items from the Available list into Entitlement Mappings and configure default portion quantities.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 12),

                DualPaneList<dynamic>(
                  height: 480,
                  availableTitle: 'Available Items Master',
                  mappedTitle: 'Entitlement Items for "${state.name.isEmpty ? 'This Cuisine' : state.name}"',
                  availableItems: state.unmappedAvailableItems,
                  mappedItems: state.mappedItems,
                  itemId: (dynamic it) => it is Item ? it.id : (it as CuisineItemMapping).itemId,
                  itemTitle: (dynamic it) => it is Item ? it.name : (it as CuisineItemMapping).itemName,
                  itemSubtitle: (dynamic it) {
                    if (it is Item) {
                      final cat = it.categoryName.isNotEmpty ? it.categoryName : 'General';
                      return '$cat • Unit: ${it.uomName}';
                    } else {
                      final m = it as CuisineItemMapping;
                      final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : 'General';
                      return '$cat • Unit: ${m.unit}';
                    }
                  },
                  itemCategory: (dynamic it) => it is Item ? it.categoryName : '',
                  onAdd: (selected) {
                    final newMappings = selected.map((s) {
                      final it = s as Item;
                      return CuisineItemMapping(
                        itemId: it.id,
                        itemName: it.name,
                        unit: it.uomName,
                        defaultQty: 1.0,
                        sortOrder: state.mappedItems.length,
                        categoryId: it.categoryId,
                        category: it.categoryName,
                        uomId: it.uomId,
                      );
                    }).toList();
                    bloc.add(CuisineEditorItemsMapped(newMappings));
                  },
                  onRemove: (selected) {
                    final ids = selected.map((s) {
                      return (s as CuisineItemMapping).itemId;
                    }).toList();
                    bloc.add(CuisineEditorItemsRemoved(ids));
                  },
                  mappedTrailing: (context, item, index) {
                    final mapping = item as CuisineItemMapping;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quantity input
                        Container(
                          width: 80,
                          height: 34,
                          margin: const EdgeInsets.only(right: 6),
                          child: TextFormField(
                            key: ValueKey('qty-${mapping.itemId}-${mapping.defaultQty}'),
                            initialValue: mapping.defaultQty % 1 == 0
                                ? mapping.defaultQty.toInt().toString()
                                : mapping.defaultQty.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Qty',
                              suffixText: mapping.unit,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final d = double.tryParse(val) ?? 1.0;
                              if (d > 0) {
                                bloc.add(
                                  CuisineEditorItemQtyChanged(
                                    itemId: mapping.itemId,
                                    qty: d,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        // Remove button
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                          tooltip: 'Remove',
                          onPressed: () {
                            bloc.add(CuisineEditorItemsRemoved([mapping.itemId]));
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
