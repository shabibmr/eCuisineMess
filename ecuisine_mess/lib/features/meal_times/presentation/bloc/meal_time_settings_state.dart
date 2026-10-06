part of 'meal_time_settings_bloc.dart';

final class MealTimeRowEdit extends Equatable {
  const MealTimeRowEdit({
    required this.id,
    required this.mealType,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.dirty = false,
    this.validationError,
  });

  factory MealTimeRowEdit.fromEntity(MealTime entity) {
    return MealTimeRowEdit(
      id: entity.id,
      mealType: entity.mealType,
      name: entity.name,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isActive: entity.isActive,
    );
  }

  final String id;
  final String mealType;
  final String name;
  final String startTime;
  final String endTime;
  final bool isActive;
  final bool dirty;
  final String? validationError;

  MealTimeRowEdit copyWith({
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
    bool? dirty,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return MealTimeRowEdit(
      id: id,
      mealType: mealType,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      dirty: dirty ?? this.dirty,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }

  @override
  List<Object?> get props => [
        id,
        mealType,
        name,
        startTime,
        endTime,
        isActive,
        dirty,
        validationError,
      ];
}

final class MealTimeSettingsState extends Equatable {
  const MealTimeSettingsState({
    this.status = Status.initial,
    this.cuisines = const [],
    this.selectedCuisineId,
    this.rows = const [],
    this.pendingCuisineId,
    this.error,
    this.notice,
  });

  final Status status;
  final List<CuisineOption> cuisines;
  final String? selectedCuisineId;
  final List<MealTimeRowEdit> rows;
  final String? pendingCuisineId;
  final String? error;
  final String? notice;

  bool get isDirty => rows.any((r) => r.dirty);

  List<CuisineOption> get activeCuisines =>
      cuisines.where((c) => c.isActive).toList();

  MealTimeSettingsState copyWith({
    Status? status,
    List<CuisineOption>? cuisines,
    String? selectedCuisineId,
    bool clearSelectedCuisine = false,
    List<MealTimeRowEdit>? rows,
    String? pendingCuisineId,
    bool clearPendingCuisine = false,
    String? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return MealTimeSettingsState(
      status: status ?? this.status,
      cuisines: cuisines ?? this.cuisines,
      selectedCuisineId: clearSelectedCuisine
          ? null
          : (selectedCuisineId ?? this.selectedCuisineId),
      rows: rows ?? this.rows,
      pendingCuisineId: clearPendingCuisine
          ? null
          : (pendingCuisineId ?? this.pendingCuisineId),
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [
        status,
        cuisines,
        selectedCuisineId,
        rows,
        pendingCuisineId,
        error,
        notice,
      ];
}
