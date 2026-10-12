import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/meal_times/presentation/bloc/meal_time_settings_bloc.dart';
import 'package:ecuisine_mess/features/meal_times/presentation/widgets/meal_time_row.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MealTimeSettingsPage extends StatelessWidget {
  const MealTimeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MealTimeSettingsBloc>()..add(const MealTimeSettingsStarted()),
      child: const _MealTimeSettingsView(),
    );
  }
}

class _MealTimeSettingsView extends StatelessWidget {
  const _MealTimeSettingsView();

  /// Three-way save/discard/cancel for cuisine switch. Uses [AppConfirmDialog]
  /// for the destructive discard path after the user declines to save.
  Future<void> _confirmCuisineSwitch(BuildContext context) async {
    final bloc = context.read<MealTimeSettingsBloc>();
    final saveFirst = await AppConfirmDialog.show(
      context: context,
      title: 'Unsaved changes',
      message:
          'This cuisine has unsaved meal-time edits. Save before switching?',
      confirmLabel: 'Save',
      cancelLabel: 'Don\'t save',
    );
    if (!context.mounted) return;
    if (saveFirst) {
      bloc.add(const MealTimePendingCuisineResolved(save: true));
      return;
    }

    final discard = await AppConfirmDialog.show(
      context: context,
      title: 'Discard changes?',
      message: 'Unsaved meal-time edits for this cuisine will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Stay',
      isDestructive: true,
    );
    if (!context.mounted) return;
    if (discard) {
      bloc.add(const MealTimePendingCuisineResolved(save: false));
    } else {
      bloc.add(const MealTimePendingCuisineCancelled());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MealTimeSettingsBloc, MealTimeSettingsState>(
          listenWhen: (p, c) =>
              p.pendingCuisineId == null && c.pendingCuisineId != null,
          listener: (context, state) => _confirmCuisineSwitch(context),
        ),
        BlocListener<MealTimeSettingsBloc, MealTimeSettingsState>(
          listenWhen: (p, c) => c.notice != null && c.notice != p.notice,
          listener: (context, state) {
            final notice = state.notice;
            if (notice == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(notice)),
            );
            context
                .read<MealTimeSettingsBloc>()
                .add(const MealTimeSettingsNoticeConsumed());
          },
        ),
      ],
      child: BlocBuilder<MealTimeSettingsBloc, MealTimeSettingsState>(
        builder: (context, state) {
          final busy = state.status == Status.loading ||
              state.status == Status.submitting;
          final cuisines = state.activeCuisines;
          final selected = state.selectedCuisineId;

          return MasterPage(
            title: 'Meal Times',
            subtitle: 'Breakfast / Lunch / Dinner windows per cuisine',
            loading: state.status == Status.loading && state.rows.isEmpty,
            error: state.status == Status.failure ? state.error : null,
            onRetry: () => context
                .read<MealTimeSettingsBloc>()
                .add(const MealTimeSettingsStarted()),
            isEmpty: cuisines.isEmpty,
            emptyMessage: 'No active cuisines. Create a cuisine first.',
            actions: [
              AppSaveButton(
                label: 'Save all',
                icon: Icons.save,
                isLoading: state.status == Status.submitting,
                onPressed: busy || !state.isDirty
                    ? null
                    : () => context
                        .read<MealTimeSettingsBloc>()
                        .add(const MealTimeSaveRequested()),
              ),
            ],
            toolbar: cuisines.isEmpty
                ? null
                : AppDropdown<String>(
                    key: ValueKey('cuisine-$selected'),
                    value: selected != null &&
                            cuisines.any((c) => c.id == selected)
                        ? selected
                        : null,
                    label: 'Cuisine',
                    items: cuisines
                        .map(
                          (c) => AppDropdownItem<String>(
                            value: c.id,
                            label: c.name,
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (id) {
                            if (id == null) return;
                            context
                                .read<MealTimeSettingsBloc>()
                                .add(MealTimeCuisineSelected(id));
                          },
                  ),
            child: ListView.separated(
              itemCount: state.rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = state.rows[index];
                return MealTimeRow(
                  row: row,
                  enabled: !busy,
                  onChanged: ({name, startTime, endTime, isActive}) {
                    context.read<MealTimeSettingsBloc>().add(
                          MealTimeRowEdited(
                            id: row.id,
                            name: name,
                            startTime: startTime,
                            endTime: endTime,
                            isActive: isActive,
                          ),
                        );
                  },
                  onSave: () => context
                      .read<MealTimeSettingsBloc>()
                      .add(MealTimeSaveRequested(rowId: row.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
