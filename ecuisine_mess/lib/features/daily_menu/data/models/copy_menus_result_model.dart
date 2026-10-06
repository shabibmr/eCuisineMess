import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_menus_result.dart';

class CopyMenusSkippedItemModel {
  const CopyMenusSkippedItemModel({
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

  factory CopyMenusSkippedItemModel.fromJson(Map<String, dynamic> json) {
    return CopyMenusSkippedItemModel(
      cuisineId: (json['cuisine_id'] ?? '').toString(),
      cuisineName: json['cuisine_name']?.toString(),
      mealType: (json['meal_type'] ?? '').toString(),
      itemId: json['item_id']?.toString(),
      itemName: json['item_name']?.toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }

  CopyMenusSkippedItem toEntity() => CopyMenusSkippedItem(
        cuisineId: cuisineId,
        cuisineName: cuisineName,
        mealType: mealType,
        itemId: itemId,
        itemName: itemName,
        reason: reason,
      );
}

class CopyMenusResultModel {
  const CopyMenusResultModel({
    required this.success,
    required this.copiedSlotsCount,
    this.skipped = const [],
    this.message,
  });

  final bool success;
  final int copiedSlotsCount;
  final List<CopyMenusSkippedItemModel> skipped;
  final String? message;

  factory CopyMenusResultModel.fromJson(Map<String, dynamic> json) {
    final rawSkipped = json['skipped'] as List<dynamic>? ?? const [];
    final count = json['copied_slots_count'] ?? json['copied'];
    return CopyMenusResultModel(
      success: json['success'] == true || json['success'] == 1,
      copiedSlotsCount: (count as num?)?.toInt() ?? 0,
      skipped: rawSkipped
          .map(
            (e) => CopyMenusSkippedItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      message: json['message']?.toString(),
    );
  }

  CopyMenusResult toEntity() => CopyMenusResult(
        success: success,
        copiedSlotsCount: copiedSlotsCount,
        skipped: skipped.map((e) => e.toEntity()).toList(),
        message: message,
      );
}
