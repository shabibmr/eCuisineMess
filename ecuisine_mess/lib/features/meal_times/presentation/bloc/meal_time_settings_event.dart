part of 'meal_time_settings_bloc.dart';

sealed class MealTimeSettingsEvent extends Equatable {
  const MealTimeSettingsEvent();

  @override
  List<Object?> get props => [];
}

final class MealTimeSettingsStarted extends MealTimeSettingsEvent {
  const MealTimeSettingsStarted();
}

final class MealTimeCuisineSelected extends MealTimeSettingsEvent {
  const MealTimeCuisineSelected(this.cuisineId);

  final String cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

final class MealTimePendingCuisineResolved extends MealTimeSettingsEvent {
  const MealTimePendingCuisineResolved({required this.save});

  final bool save;

  @override
  List<Object?> get props => [save];
}

final class MealTimePendingCuisineCancelled extends MealTimeSettingsEvent {
  const MealTimePendingCuisineCancelled();
}

final class MealTimeRowEdited extends MealTimeSettingsEvent {
  const MealTimeRowEdited({
    required this.id,
    this.name,
    this.startTime,
    this.endTime,
    this.isActive,
  });

  final String id;
  final String? name;
  final String? startTime;
  final String? endTime;
  final bool? isActive;

  @override
  List<Object?> get props => [id, name, startTime, endTime, isActive];
}

final class MealTimeSaveRequested extends MealTimeSettingsEvent {
  const MealTimeSaveRequested({this.rowId});

  /// When null, saves all dirty rows.
  final String? rowId;

  @override
  List<Object?> get props => [rowId];
}

final class MealTimeSettingsNoticeConsumed extends MealTimeSettingsEvent {
  const MealTimeSettingsNoticeConsumed();
}
