import 'package:ecuisine_mess/features/daily_menu/domain/entities/save_day_result.dart';

class SaveDayResultModel {
  const SaveDayResultModel({
    required this.success,
    required this.menuDate,
    required this.savedSlotsCount,
    this.message,
  });

  final bool success;
  final String menuDate;
  final int savedSlotsCount;
  final String? message;

  factory SaveDayResultModel.fromJson(Map<String, dynamic> json) {
    final date = json['menu_date']?.toString() ?? '';
    return SaveDayResultModel(
      success: json['success'] == true || json['success'] == 1,
      menuDate: date.length >= 10 ? date.substring(0, 10) : date,
      savedSlotsCount: (json['saved_slots_count'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString(),
    );
  }

  SaveDayResult toEntity() => SaveDayResult(
        success: success,
        menuDate: menuDate,
        savedSlotsCount: savedSlotsCount,
        message: message,
      );
}
