import 'package:equatable/equatable.dart';

class CopyMealSkippedItem extends Equatable {
  const CopyMealSkippedItem({
    required this.toCuisineId,
    this.toCuisineName,
    this.itemId,
    this.itemName,
    required this.reason,
  });

  final String toCuisineId;
  final String? toCuisineName;
  final String? itemId;
  final String? itemName;
  final String reason;

  @override
  List<Object?> get props =>
      [toCuisineId, toCuisineName, itemId, itemName, reason];
}

class CopyMealResult extends Equatable {
  const CopyMealResult({
    required this.success,
    this.copiedCuisines = const [],
    this.skipped = const [],
    this.message,
  });

  final bool success;
  final List<String> copiedCuisines;
  final List<CopyMealSkippedItem> skipped;
  final String? message;

  @override
  List<Object?> get props => [success, copiedCuisines, skipped, message];
}
