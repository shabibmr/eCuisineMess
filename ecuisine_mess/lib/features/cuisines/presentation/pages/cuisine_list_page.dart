import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/bloc/cuisine_list_bloc.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/pages/cuisine_editor_page.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_create_button.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_search_field.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CuisineListPage extends StatelessWidget {
  const CuisineListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CuisineListBloc>()..add(const CuisineListStarted()),
      child: const _CuisineListView(),
    );
  }
}

class _CuisineListView extends StatefulWidget {
  const _CuisineListView();

  @override
  State<_CuisineListView> createState() => _CuisineListViewState();
}

class _CuisineListViewState extends State<_CuisineListView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEditor(BuildContext context, {String? cuisineId}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CuisineEditorPage(cuisineId: cuisineId),
      ),
    );
    if (result == true && context.mounted) {
      context.read<CuisineListBloc>().add(const CuisineListRefreshed());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Cuisine cuisine) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Cuisine?',
      message:
          'Are you sure you want to delete "${cuisine.cuisineName}"?\n\n'
          'If this cuisine is linked to members or bills, it will be marked as '
          'inactive instead of deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      context.read<CuisineListBloc>().add(CuisineDeleteRequested(cuisine.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CuisineListBloc, CuisineListState>(
      listener: (context, state) {
        if (state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notice!),
              backgroundColor: Colors.teal.shade800,
            ),
          );
          context.read<CuisineListBloc>().add(const CuisineNoticeConsumed());
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<CuisineListBloc>();
        final cuisines = state.filteredCuisines;

        return MasterPage(
          title: 'Cuisines & Menu Mappings',
          subtitle: 'Active meal packages and their entitled menu items',
          loading: state.status == Status.loading && state.cuisines.isEmpty,
          error: state.error,
          onRetry: () => bloc.add(const CuisineListRefreshed()),
          isEmpty: state.status == Status.success && cuisines.isEmpty,
          emptyMessage: state.cuisines.isEmpty
              ? 'No cuisines configured yet.'
              : 'No cuisines matching filters.',
          actions: [
            AppSearchField(
              controller: _searchCtrl,
              hintText: 'Search cuisines...',
              width: 220,
              height: 38,
              onChanged: (val) => bloc.add(CuisineSearchChanged(val)),
              onCleared: () => bloc.add(const CuisineSearchChanged('')),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Show Inactive', style: TextStyle(fontSize: 12)),
              selected: state.showInactive,
              onSelected: (val) => bloc.add(CuisineFilterInactiveToggled(val)),
            ),
            const SizedBox(width: 8),
            AppRefreshButton(
              onPressed: () => bloc.add(const CuisineListRefreshed()),
            ),
            const SizedBox(width: 8),
            AppCreateButton(
              label: 'New Cuisine',
              onPressed: () => _openEditor(context),
            ),
          ],
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cuisines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = cuisines[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: c.isActive
                        ? Colors.grey.shade300
                        : Colors.amber.shade300,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.cuisineName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AppStatusBadge.fromBool(
                                      c.isActive,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                if (c.description != null &&
                                    c.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    c.description!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.restaurant_menu, size: 16),
                                label: Text(
                                  '${c.mappedItemsCount} items mapped',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.blue.shade50,
                              ),
                              Chip(
                                avatar: const Icon(Icons.people_outline, size: 16),
                                label: Text(
                                  '${c.activeMembersCount} diners',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.purple.shade50,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit & Map Items',
                                onPressed: () =>
                                    _openEditor(context, cuisineId: c.id),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Cuisine',
                                onPressed: () => _confirmDelete(context, c),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (c.items.isNotEmpty) ...[
                        const Divider(height: 20),
                        const Text(
                          'Mapped Entitlements:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: c.items.map((itm) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                '${itm.itemName} (${itm.defaultQty % 1 == 0 ? itm.defaultQty.toInt() : itm.defaultQty} ${itm.unit})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
