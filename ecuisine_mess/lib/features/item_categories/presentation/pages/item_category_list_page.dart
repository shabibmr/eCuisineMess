import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/save_item_category.dart';
import 'package:ecuisine_mess/features/item_categories/presentation/bloc/item_category_list_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/layout/form_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
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

  Future<void> _showAddDialog(BuildContext context) async {
    final bloc = context.read<ItemCategoryListBloc>();
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showAppFormDialog(
      context: context,
      title: 'Add Item Category',
      formKey: formKey,
      confirmLabel: 'Save',
      body: TextFormField(
        controller: nameCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'Snack',
          border: OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      return;
    }
    final sortOrder = bloc.state.categories.length + 1;
    bloc.add(
      ItemCategorySaveRequested(
        SaveItemCategoryParams(
          name: nameCtrl.text.trim(),
          sortOrder: sortOrder,
          isActive: true,
        ),
      ),
    );
    nameCtrl.dispose();
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ItemCategory category,
  ) async {
    final bloc = context.read<ItemCategoryListBloc>();
    final nameCtrl = TextEditingController(text: category.name);
    final sortCtrl = TextEditingController(text: '${category.sortOrder}');
    var isActive = category.isActive;
    final formKey = GlobalKey<FormState>();

    final ok = await showAppFormDialog(
      context: context,
      title: 'Edit Item Category',
      formKey: formKey,
      confirmLabel: 'Update',
      body: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sortCtrl,
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
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      sortCtrl.dispose();
      return;
    }

    bloc.add(
      ItemCategorySaveRequested(
        SaveItemCategoryParams(
          id: category.id,
          name: nameCtrl.text.trim(),
          sortOrder: int.parse(sortCtrl.text.trim()),
          isActive: isActive,
        ),
      ),
    );
    nameCtrl.dispose();
    sortCtrl.dispose();
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
            IconButton(
              onPressed: () => context
                  .read<ItemCategoryListBloc>()
                  .add(const ItemCategoryListRefreshed()),
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
          child: Card(
            child: ListView.separated(
              itemCount: state.categories.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = state.categories[i];
                return InkWell(
                  onDoubleTap: () => _showEditDialog(context, c),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${c.sortOrder}')),
                    title: Text(c.name),
                    subtitle: Text(
                      c.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: c.isActive
                        ? const Chip(
                            label: Text('Active'),
                            visualDensity: VisualDensity.compact,
                          )
                        : const Chip(
                            label: Text('Inactive'),
                            visualDensity: VisualDensity.compact,
                          ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
