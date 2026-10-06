part of 'cuisine_editor_bloc.dart';

class CuisineEditorState extends Equatable {
  const CuisineEditorState({
    this.status = Status.initial,
    this.cuisineId,
    this.name = '',
    this.description = '',
    this.isActive = true,
    this.availableItems = const [],
    this.mappedItems = const [],
    this.otherCuisines = const [],
    this.isSaving = false,
    this.saved = false,
    this.savedMessage,
    this.error,
    this.unmapConflictMessage,
    this.unmapConflictDetails,
  });

  final Status status;
  final String? cuisineId;
  final String name;
  final String description;
  final bool isActive;
  final List<Item> availableItems;
  final List<CuisineItemMapping> mappedItems;
  final List<Cuisine> otherCuisines;
  final bool isSaving;
  final bool saved;
  final String? savedMessage;
  final String? error;
  final String? unmapConflictMessage;
  final Map<String, dynamic>? unmapConflictDetails;

  bool get isNew => cuisineId == null || cuisineId!.isEmpty;

  bool get hasUnsavedWarning => mappedItems.isEmpty;

  /// Items available for mapping that are NOT already in mappedItems
  List<Item> get unmappedAvailableItems {
    final mappedIds = mappedItems.map((m) => m.itemId).toSet();
    return availableItems.where((i) => !mappedIds.contains(i.id)).toList();
  }

  CuisineEditorState copyWith({
    Status? status,
    String? cuisineId,
    String? name,
    String? description,
    bool? isActive,
    List<Item>? availableItems,
    List<CuisineItemMapping>? mappedItems,
    List<Cuisine>? otherCuisines,
    bool? isSaving,
    bool? saved,
    String? savedMessage,
    String? error,
    bool clearError = false,
    String? unmapConflictMessage,
    Map<String, dynamic>? unmapConflictDetails,
    bool clearConflict = false,
  }) {
    return CuisineEditorState(
      status: status ?? this.status,
      cuisineId: cuisineId ?? this.cuisineId,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      availableItems: availableItems ?? this.availableItems,
      mappedItems: mappedItems ?? this.mappedItems,
      otherCuisines: otherCuisines ?? this.otherCuisines,
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
      savedMessage: savedMessage ?? this.savedMessage,
      error: clearError ? null : (error ?? this.error),
      unmapConflictMessage: clearConflict
          ? null
          : (unmapConflictMessage ?? this.unmapConflictMessage),
      unmapConflictDetails: clearConflict
          ? null
          : (unmapConflictDetails ?? this.unmapConflictDetails),
    );
  }

  @override
  List<Object?> get props => [
        status,
        cuisineId,
        name,
        description,
        isActive,
        availableItems,
        mappedItems,
        otherCuisines,
        isSaving,
        saved,
        savedMessage,
        error,
        unmapConflictMessage,
        unmapConflictDetails,
      ];
}
