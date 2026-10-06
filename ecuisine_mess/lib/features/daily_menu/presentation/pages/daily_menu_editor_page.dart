import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_cuisine_pane.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_date_bar.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_item_grid.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_meal_tabs.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_status_banners.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/error_banner.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DailyMenuEditorPage extends StatelessWidget {
  const DailyMenuEditorPage({
    super.key,
    this.menuDate,
    this.cuisineId,
    this.mealType,
  });

  final String? menuDate;
  final String? cuisineId;
  final String? mealType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DailyMenuEditorBloc>()
        ..add(
          DailyMenuEditorStarted(
            menuDate: menuDate,
            cuisineId: cuisineId,
            mealType: mealType,
          ),
        ),
      child: const _DailyMenuEditorView(),
    );
  }
}

class _DailyMenuEditorView extends StatelessWidget {
  const _DailyMenuEditorView();

  Future<void> _confirmPendingDate(BuildContext context) async {
    final bloc = context.read<DailyMenuEditorBloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'This date has unsaved menu edits. Save before changing the date?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (result) {
      case 'save':
        bloc.add(const DailyMenuPendingDateResolved(save: true));
      case 'discard':
        bloc.add(const DailyMenuPendingDateResolved(save: false));
      default:
        bloc.add(const DailyMenuPendingDateCancelled());
    }
  }

  Future<void> _pickDate(BuildContext context, String current) async {
    final parts = current.split('-');
    DateTime initial = DateTime.now();
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        initial = DateTime(y, m, d);
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null || !context.mounted) return;
    context.read<DailyMenuEditorBloc>().add(
          DailyMenuDateChanged(DailyMenuEditorBloc.formatDate(picked)),
        );
  }

  Future<void> _copyFromDate(BuildContext context, String currentDate) async {
    final formKey = GlobalKey<FormState>();
    final dateCtrl = TextEditingController();
    var overwrite = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Copy From Date'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: dateCtrl,
                        decoration: InputDecoration(
                          labelText: 'Source date (YYYY-MM-DD)',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.now()
                                    .subtract(const Duration(days: 1)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2040),
                              );
                              if (picked == null) return;
                              dateCtrl.text =
                                  DailyMenuEditorBloc.formatDate(picked);
                            },
                          ),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                            return 'Use YYYY-MM-DD';
                          }
                          if (value == currentDate) {
                            return 'Choose a different date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Overwrite existing unlocked slots'),
                        value: overwrite,
                        onChanged: (v) =>
                            setLocal(() => overwrite = v ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Copy'),
                ),
              ],
            );
          },
        );
      },
    );

    final fromDate = dateCtrl.text.trim();
    dateCtrl.dispose();
    if (confirmed != true || !context.mounted) return;
    context.read<DailyMenuEditorBloc>().add(
          DailyMenuCopyFromDateRequested(
            fromDate: fromDate,
            overwrite: overwrite,
          ),
        );
  }

  Future<void> _copyMealToCuisines(
    BuildContext context,
    DailyMenuEditorState state,
  ) async {
    final currentId = state.selectedCuisineId;
    if (currentId == null) return;
    final targets = state.cuisines.where((c) => c.id != currentId).toList();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other cuisines to copy to')),
      );
      return;
    }

    final selected = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Copy meal to cuisines'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Copy ${state.selectedMealType.toLowerCase()} items to:',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: targets
                            .map(
                              (c) => CheckboxListTile(
                                dense: true,
                                title: Text(c.name),
                                value: selected.contains(c.id),
                                onChanged: (v) {
                                  setLocal(() {
                                    if (v == true) {
                                      selected.add(c.id);
                                    } else {
                                      selected.remove(c.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: const Text('Copy'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !context.mounted) return;
    context.read<DailyMenuEditorBloc>().add(
          DailyMenuCopyMealRequested(toCuisineIds: selected.toList()),
        );
  }

  String _cuisineName(List<CuisineOption> cuisines, String? id) {
    if (id == null) return 'cuisine';
    for (final c in cuisines) {
      if (c.id == id) return c.name;
    }
    return 'cuisine';
  }

  String _footerStatus(DailyMenuEditorState state) {
    final name = _cuisineName(state.cuisines, state.selectedCuisineId);
    CuisineMenuStatus? readiness;
    for (final r in state.readiness) {
      if (r.cuisineId == state.selectedCuisineId) {
        readiness = r;
        break;
      }
    }
    final b = readiness?.breakfast == true ? '✔' : '✖';
    final l = readiness?.lunch == true ? '✔' : '✖';
    final d = readiness?.dinner == true ? '✔' : '✖';
    return 'Status for $name: B $b   L $l   D $d';
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DailyMenuEditorBloc, DailyMenuEditorState>(
          listenWhen: (p, c) => p.pendingDate == null && c.pendingDate != null,
          listener: (context, state) => _confirmPendingDate(context),
        ),
        BlocListener<DailyMenuEditorBloc, DailyMenuEditorState>(
          listenWhen: (p, c) => c.notice != null && c.notice != p.notice,
          listener: (context, state) {
            final notice = state.notice;
            if (notice == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(notice)),
            );
            context
                .read<DailyMenuEditorBloc>()
                .add(const DailyMenuNoticeConsumed());
          },
        ),
      ],
      child: BlocBuilder<DailyMenuEditorBloc, DailyMenuEditorState>(
        builder: (context, state) {
          final busy = state.status == Status.loading ||
              state.status == Status.submitting;
          final initialLoading =
              state.status == Status.loading && state.cuisines.isEmpty;
          final hardFailure = state.status == Status.failure &&
              state.cuisines.isEmpty &&
              state.slots.isEmpty;
          final softError = state.status == Status.failure && !hardFailure
              ? state.error
              : null;
          final readOnly = state.isPastDate || state.isCurrentMealLocked;
          final canSave = !state.isPastDate && state.dirty && !busy;

          return MasterPage(
            title: 'Daily Menu',
            subtitle: 'Plan breakfast / lunch / dinner per cuisine for a date',
            loading: initialLoading,
            error: hardFailure ? state.error : null,
            onRetry: () => context.read<DailyMenuEditorBloc>().add(
                  DailyMenuEditorStarted(
                    menuDate: state.menuDate.isEmpty ? null : state.menuDate,
                    cuisineId: state.selectedCuisineId,
                    mealType: state.selectedMealType,
                  ),
                ),
            isEmpty: !initialLoading &&
                !hardFailure &&
                state.cuisines.isEmpty,
            emptyMessage: 'No active cuisines. Create a cuisine first.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MenuDateBar(
                  menuDate: state.menuDate,
                  enabled: !busy,
                  readOnly: state.isPastDate,
                  canSave: canSave,
                  dirty: state.dirty,
                  onPrevDay: () => context
                      .read<DailyMenuEditorBloc>()
                      .add(const DailyMenuDateShifted(-1)),
                  onNextDay: () => context
                      .read<DailyMenuEditorBloc>()
                      .add(const DailyMenuDateShifted(1)),
                  onJumpToday: () => context
                      .read<DailyMenuEditorBloc>()
                      .add(const DailyMenuJumpToday()),
                  onPickDate: () => _pickDate(context, state.menuDate),
                  onCopyFromDate: () =>
                      _copyFromDate(context, state.menuDate),
                  onHistory: () => context.goNamed(AppRoutes.menuHistory.name),
                  onReset: () => context
                      .read<DailyMenuEditorBloc>()
                      .add(const DailyMenuResetRequested()),
                  onSave: () => context
                      .read<DailyMenuEditorBloc>()
                      .add(const DailyMenuSaveRequested()),
                ),
                if (state.isPastDate) ...[
                  const SizedBox(height: 10),
                  const MenuPastDateBanner(),
                ],
                if (softError != null) ...[
                  const SizedBox(height: 10),
                  ErrorBanner(
                    message: softError,
                    onRetry: state.conflictCode == null
                        ? () => context.read<DailyMenuEditorBloc>().add(
                              DailyMenuEditorStarted(
                                menuDate: state.menuDate,
                                cuisineId: state.selectedCuisineId,
                                mealType: state.selectedMealType,
                              ),
                            )
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 780;
                      final cuisinePane = SizedBox(
                        width: narrow ? double.infinity : 240,
                        height: narrow ? 180 : double.infinity,
                        child: MenuCuisinePane(
                          cuisines: state.cuisines,
                          readiness: state.readiness,
                          selectedCuisineId: state.selectedCuisineId,
                          onSelected: (id) => context
                              .read<DailyMenuEditorBloc>()
                              .add(DailyMenuCuisineSelected(id)),
                        ),
                      );

                      final mealPane = Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MenuMealTabs(
                                selectedMealType: state.selectedMealType,
                                breakfastCount:
                                    state.itemCountForMeal('BREAKFAST'),
                                lunchCount: state.itemCountForMeal('LUNCH'),
                                dinnerCount: state.itemCountForMeal('DINNER'),
                                enabled: !busy,
                                readOnly: readOnly,
                                onMealSelected: (meal) => context
                                    .read<DailyMenuEditorBloc>()
                                    .add(DailyMenuMealSelected(meal)),
                                onAddAllMapped: () => context
                                    .read<DailyMenuEditorBloc>()
                                    .add(const DailyMenuItemsAddAllMapped()),
                                onCopyToCuisines: () =>
                                    _copyMealToCuisines(context, state),
                              ),
                              if (state.isCurrentMealLocked &&
                                  !state.isPastDate) ...[
                                const SizedBox(height: 10),
                                const MenuMealLockedBanner(),
                              ],
                              const SizedBox(height: 12),
                              Expanded(
                                child: MenuItemGrid(
                                  items: state.currentSlot?.items ?? const [],
                                  availableMappedItems:
                                      state.availableMappedItems,
                                  readOnly: readOnly || busy,
                                  hasMappedItems:
                                      state.mappedItems.isNotEmpty,
                                  cuisineName: _cuisineName(
                                    state.cuisines,
                                    state.selectedCuisineId,
                                  ),
                                  onAddItem: (id) => context
                                      .read<DailyMenuEditorBloc>()
                                      .add(DailyMenuItemAdded(id)),
                                  onRemoveItem: (id) => context
                                      .read<DailyMenuEditorBloc>()
                                      .add(DailyMenuItemRemoved(id)),
                                  onQtyChanged: (id, qty) => context
                                      .read<DailyMenuEditorBloc>()
                                      .add(
                                        DailyMenuItemQtyChanged(
                                          itemId: id,
                                          quantity: qty,
                                        ),
                                      ),
                                  onOpenCuisineEditor:
                                      state.selectedCuisineId == null
                                          ? null
                                          : () => context.push(
                                                AppRoutes.cuisineEdit.path
                                                    .replaceFirst(
                                                  ':id',
                                                  state.selectedCuisineId!,
                                                ),
                                              ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Divider(height: 1, color: Theme.of(context).dividerColor),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _footerStatus(state),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Changes save across all cuisines for this date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            cuisinePane,
                            const SizedBox(height: 12),
                            Expanded(child: mealPane),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          cuisinePane,
                          const SizedBox(width: 12),
                          Expanded(child: mealPane),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
