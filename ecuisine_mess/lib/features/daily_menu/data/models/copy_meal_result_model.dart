import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_meal_result.dart';

class CopyMealSkippedItemModel {
  const CopyMealSkippedItemModel({
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

  factory CopyMealSkippedItemModel.fromJson(Map<String, dynamic> json) {
    return CopyMealSkippedItemModel(
      toCuisineId: (json['to_cuisine_id'] ?? '').toString(),
      toCuisineName: json['to_cuisine_name']?.toString(),
      itemId: json['item_id']?.toString(),
      itemName: json['item_name']?.toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  CopyMealSkippedItem toEntity() => CopyMealSkippedItem(
        toCuisineId: toCuisineId,
        toCuisineName: toCuisineName,
        itemId: itemId,
        itemName: itemName,
        reason: reason,
      );
}

class CopyMealResultModel {
  const CopyMealResultModel({
    required this.success,
    this.copiedCuisines = const [],
    this.skipped = const [],
    this.message,
  });

  final bool success;
  final List<String> copiedCuisines;
  final List<CopyMealSkippedItemModel> skipped;
  final String? message;

  factory CopyMealResultModel.fromJson(Map<String, dynamic> json) {
    final rawCopied = json['copied_cuisines'] as List<dynamic>? ?? const [];
    final rawSkipped = json['skipped'] as List<dynamic>? ?? const [];
    return CopyMealResultModel(
      success: json['success'] == true || json['success'] == 1,
      copiedCuisines: rawCopied.map((e) => e.toString()).toList(),
      skipped: rawSkipped
          .map(
            (e) => CopyMealSkippedItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      message: json['message']?.toString(),
    );
  }

  CopyMealResult toEntity() => CopyMealResult(
        success: success,
        copiedCuisines: copiedCuisines,
        skipped: skipped.map((e) => e.toEntity()).toList(),
        message: message,
      );
}
