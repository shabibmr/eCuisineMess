import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/features/items/domain/entities/uom.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/save_item.dart';
import 'package:ecuisine_mess/features/items/presentation/bloc/item_list_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_create_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_form_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:ecuisine_mess/shared/widgets/tables/app_separated_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemListPage extends StatelessWidget {
  const ItemListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ItemListBloc>()..add(const ItemListStarted()),
      child: const _ItemListView(),
    );
  }
}

class _ItemListView extends StatelessWidget {
  const _ItemListView();

  Future<void> _openFormDialog(BuildContext context, [Item? item]) async {
    final bloc = context.read<ItemListBloc>();
    final state = bloc.state;

    if (item == null &&
        (state.activeCategories.isEmpty || state.uoms.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least one category and UOM')),
      );
      return;
    }

    final params = await showDialog<SaveItemParams>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ItemFormDialog(
        item: item,
        categories: state.categories,
        activeCategories: state.activeCategories,
        uoms: state.uoms,
      ),
    );

    if (params != null && context.mounted) {
      bloc.add(ItemSaveRequested(params));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemListBloc, ItemListState>(
      listenWhen: (prev, next) =>
          next.notice != null ||
          (next.status == Status.failure &&
              next.error != null &&
              prev.status == Status.submitting),
      listener: (context, state) {
        if (state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notice!)),
          );
          context
              .read<ItemListBloc>()
              .add(const ItemListNoticeConsumed());
        } else if (state.status == Status.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final loading =
            state.status == Status.loading || state.status == Status.initial;
        final showError = state.status == Status.failure &&
            state.items.isEmpty &&
            state.error != null;

        return MasterPage(
          title: 'Items',
          subtitle: 'Double-click a row to edit',
          loading: loading,
          error: showError ? state.error : null,
          onRetry: () => context
              .read<ItemListBloc>()
              .add(const ItemListRefreshed()),
          isEmpty: !loading && !showError && state.items.isEmpty,
          emptyMessage: 'No items yet',
          actions: [
            AppRefreshButton(
              onPressed: () => context
                  .read<ItemListBloc>()
                  .add(const ItemListRefreshed()),
            ),
            const SizedBox(width: 8),
            AppCreateButton(
              label: 'Add Item',
              onPressed: () => _openFormDialog(context),
            ),
          ],
          child: AppSeparatedListCard(
            itemCount: state.items.length,
            itemBuilder: (_, i) {
              final item = state.items[i];
              return InkWell(
                onDoubleTap: () => _openFormDialog(context, item),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      item.name.isNotEmpty
                          ? item.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.categoryName} · ${item.uomName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: AppStatusBadge.fromBool(item.isActive),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({
    this.item,
    required this.categories,
    required this.activeCategories,
    required this.uoms,
  });

  final Item? item;
  final List<ItemCategory> categories;
  final List<ItemCategory> activeCategories;
  final List<Uom> uoms;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _categoryId;
  String? _uomId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _isActive = widget.item?.isActive ?? true;

    if (widget.item == null) {
      _categoryId = widget.activeCategories.isNotEmpty
          ? widget.activeCategories.first.id
          : null;
      _uomId = widget.uoms
          .firstWhere(
            (u) => u.name == 'Nos',
            orElse: () => widget.uoms.first,
          )
          .id;
    } else {
      _categoryId = widget.item!.categoryId;
      if (_categoryId == null ||
          !widget.categories.any((c) => c.id == _categoryId)) {
        _categoryId = widget.activeCategories.isNotEmpty
            ? widget.activeCategories.first.id
            : null;
      }
      _uomId = widget.item!.uomId;
      if (_uomId == null || !widget.uoms.any((u) => u.id == _uomId)) {
        Uom? match;
        for (final u in widget.uoms) {
          if (u.name == widget.item!.uomName) {
            match = u;
            break;
          }
        }
        match ??= widget.uoms.isNotEmpty ? widget.uoms.first : null;
        _uomId = match?.id;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      SaveItemParams(
        id: widget.item?.id,
        name: _nameCtrl.text.trim(),
        categoryId: _categoryId!,
        uomId: _uomId!,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final categoryChoices = <ItemCategory>[
      ...widget.activeCategories,
      if (_categoryId != null &&
          !widget.activeCategories.any((c) => c.id == _categoryId))
        widget.categories.firstWhere((c) => c.id == _categoryId),
    ];

    return AppFormDialog(
      title: isEdit ? 'Edit Item' : 'Add Item',
      formKey: _formKey,
      confirmLabel: isEdit ? 'Update' : 'Save',
      onConfirm: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          AppDropdown<String>(
            key: ValueKey('${isEdit ? "edit" : "add"}-cat-$_categoryId'),
            value: _categoryId,
            label: 'Category',
            items: categoryChoices
                .map(
                  (c) => AppDropdownItem(
                    value: c.id,
                    label: c.name,
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          AppDropdown<String>(
            key: ValueKey('${isEdit ? "edit" : "add"}-uom-$_uomId'),
            value: _uomId,
            label: 'UOM',
            items: widget.uoms
                .map(
                  (u) => AppDropdownItem(
                    value: u.id,
                    label: u.name,
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _uomId = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          if (isEdit) ...[
            const SizedBox(height: 8),
            AppSwitchTile(
              title: 'Active',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ],
      ),
    );
  }
}

