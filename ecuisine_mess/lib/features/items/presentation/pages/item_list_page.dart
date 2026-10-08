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

  Future<void> _showAddDialog(BuildContext context) async {
    final bloc = context.read<ItemListBloc>();
    final state = bloc.state;
    final activeCategories = state.activeCategories;
    final uoms = state.uoms;

    if (activeCategories.isEmpty || uoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least one category and UOM')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    String? categoryId = activeCategories.first.id;
    String? uomId = uoms
        .firstWhere(
          (u) => u.name == 'Nos',
          orElse: () => uoms.first,
        )
        .id;
    final formKey = GlobalKey<FormState>();

    final ok = await showAppFormDialog(
      context: context,
      title: 'Add Item',
      formKey: formKey,
      confirmLabel: 'Save',
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
              AppDropdown<String>(
                key: ValueKey('add-cat-$categoryId'),
                value: categoryId,
                label: 'Category',
                items: activeCategories
                    .map(
                      (c) => AppDropdownItem(
                        value: c.id,
                        label: c.name,
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => categoryId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                key: ValueKey('add-uom-$uomId'),
                value: uomId,
                label: 'UOM',
                items: uoms
                    .map(
                      (u) => AppDropdownItem(
                        value: u.id,
                        label: u.name,
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => uomId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) {
      nameCtrl.dispose();
      return;
    }

    bloc.add(
      ItemSaveRequested(
        SaveItemParams(
          name: nameCtrl.text.trim(),
          categoryId: categoryId!,
          uomId: uomId!,
        ),
      ),
    );
    nameCtrl.dispose();
  }

  Future<void> _showEditDialog(BuildContext context, Item item) async {
    final bloc = context.read<ItemListBloc>();
    final state = bloc.state;
    final categories = state.categories;
    final activeCategories = state.activeCategories;
    final uoms = state.uoms;

    final nameCtrl = TextEditingController(text: item.name);
    var categoryId = item.categoryId;
    if (categoryId == null || !categories.any((c) => c.id == categoryId)) {
      categoryId =
          activeCategories.isNotEmpty ? activeCategories.first.id : null;
    }
    var uomId = item.uomId;
    if (uomId == null || !uoms.any((u) => u.id == uomId)) {
      Uom? match;
      for (final u in uoms) {
        if (u.name == item.uomName) {
          match = u;
          break;
        }
      }
      match ??= uoms.isNotEmpty ? uoms.first : null;
      uomId = match?.id;
    }
    var isActive = item.isActive;
    final formKey = GlobalKey<FormState>();

    final categoryChoices = <ItemCategory>[
      ...activeCategories,
      if (categoryId != null &&
          !activeCategories.any((c) => c.id == categoryId))
        categories.firstWhere((c) => c.id == categoryId),
    ];

    final ok = await showAppFormDialog(
      context: context,
      title: 'Edit Item',
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
              AppDropdown<String>(
                key: ValueKey('edit-cat-$categoryId'),
                value: categoryId,
                label: 'Category',
                items: categoryChoices
                    .map(
                      (c) => AppDropdownItem(
                        value: c.id,
                        label: c.name,
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => categoryId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                key: ValueKey('edit-uom-$uomId'),
                value: uomId,
                label: 'UOM',
                items: uoms
                    .map(
                      (u) => AppDropdownItem(
                        value: u.id,
                        label: u.name,
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => uomId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              AppSwitchTile(
                title: 'Active',
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
      return;
    }

    bloc.add(
      ItemSaveRequested(
        SaveItemParams(
          id: item.id,
          name: nameCtrl.text.trim(),
          categoryId: categoryId!,
          uomId: uomId!,
          isActive: isActive,
        ),
      ),
    );
    nameCtrl.dispose();
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
              onPressed: () => _showAddDialog(context),
            ),
          ],
          child: AppSeparatedListCard(
            itemCount: state.items.length,
            itemBuilder: (_, i) {
              final item = state.items[i];
              return InkWell(
                onDoubleTap: () => _showEditDialog(context, item),
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
