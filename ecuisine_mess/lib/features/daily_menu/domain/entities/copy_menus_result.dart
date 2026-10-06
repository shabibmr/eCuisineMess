import 'package:equatable/equatable.dart';

class CopyMenusSkippedItem extends Equatable {
  const CopyMenusSkippedItem({
    required this.cuisineId,
    this.cuisineName,
    required this.mealType,
    this.itemId,
    this.itemName,
    required this.reason,
  });

  final String cuisineId;
  final String? cuisineName;
  final String mealType;
  final String? itemId;
  final String? itemName;
  final String reason;

  @override
  List<Object?> get props =>
      [cuisineId, cuisineName, mealType, itemId, itemName, reason];
}

class CopyMenusResult extends Equatable {
  const CopyMenusResult({
    required this.success,
    required this.copiedSlotsCount,
    this.skipped = const [],
    this.message,
  });

  final bool success;
  final int copiedSlotsCount;
  final List<CopyMenusSkippedItem> skipped;
  final String? message;

  @override
  List<Object?> get props => [success, copiedSlotsCount, skipped, message];
}
