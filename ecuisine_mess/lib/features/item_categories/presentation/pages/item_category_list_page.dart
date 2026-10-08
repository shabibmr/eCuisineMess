import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/save_item_category.dart';
import 'package:ecuisine_mess/features/item_categories/presentation/bloc/item_category_list_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_create_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_form_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:ecuisine_mess/shared/widgets/tables/app_separated_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemCategoryListPage extends StatelessWidget {
  const ItemCategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ItemCategoryListBloc>()
        ..add(const ItemCategoryListStarted()),
      child: const _ItemCategoryListView(),
    );
  }
}

class _ItemCategoryListView extends StatelessWidget {
  const _ItemCategoryListView();

  Future<void> _openFormDialog(
    BuildContext context, [
    ItemCategory? category,
  ]) async {
    final bloc = context.read<ItemCategoryListBloc>();
    final defaultSort = bloc.state.categories.length + 1;

    final params = await showDialog<SaveItemCategoryParams>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ItemCategoryFormDialog(
        category: category,
        defaultSortOrder: defaultSort,
      ),
    );

    if (params != null && context.mounted) {
      bloc.add(ItemCategorySaveRequested(params));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemCategoryListBloc, ItemCategoryListState>(
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
              .read<ItemCategoryListBloc>()
              .add(const ItemCategoryListNoticeConsumed());
        } else if (state.status == Status.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == Status.loading ||
            state.status == Status.initial;
        final showError = state.status == Status.failure &&
            state.categories.isEmpty &&
            state.error != null;

        return MasterPage(
          title: 'Item Categories',
          subtitle: 'Double-click a row to edit',
          loading: loading,
          error: showError ? state.error : null,
          onRetry: () => context
              .read<ItemCategoryListBloc>()
              .add(const ItemCategoryListRefreshed()),
          isEmpty: !loading && !showError && state.categories.isEmpty,
          emptyMessage: 'No categories yet',
          actions: [
            AppRefreshButton(
              onPressed: () => context
                  .read<ItemCategoryListBloc>()
                  .add(const ItemCategoryListRefreshed()),
            ),
            const SizedBox(width: 8),
            AppCreateButton(
              label: 'Add Category',
              onPressed: () => _openFormDialog(context),
            ),
          ],
          child: AppSeparatedListCard(
            itemCount: state.categories.length,
            itemBuilder: (_, i) {
              final c = state.categories[i];
              return InkWell(
                onDoubleTap: () => _openFormDialog(context, c),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${c.sortOrder}')),
                  title: Text(c.name),
                  subtitle: Text(
                    c.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: AppStatusBadge.fromBool(c.isActive),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ItemCategoryFormDialog extends StatefulWidget {
  const _ItemCategoryFormDialog({
    this.category,
    required this.defaultSortOrder,
  });

  final ItemCategory? category;
  final int defaultSortOrder;

  @override
  State<_ItemCategoryFormDialog> createState() =>
      _ItemCategoryFormDialogState();
}

class _ItemCategoryFormDialogState extends State<_ItemCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sortCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _sortCtrl = TextEditingController(
      text: widget.category != null
          ? '${widget.category!.sortOrder}'
          : '${widget.defaultSortOrder}',
    );
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final sort = int.tryParse(_sortCtrl.text.trim()) ?? widget.defaultSortOrder;
    Navigator.of(context).pop(
      SaveItemCategoryParams(
        id: widget.category?.id,
        name: _nameCtrl.text.trim(),
        sortOrder: sort,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AppFormDialog(
      title: isEdit ? 'Edit Item Category' : 'Add Item Category',
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
              hintText: 'Snack',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sortCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sort order',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (int.tryParse(v.trim()) == null) return 'Enter a number';
              return null;
            },
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

