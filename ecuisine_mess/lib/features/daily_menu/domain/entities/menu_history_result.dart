import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:equatable/equatable.dart';

class MenuHistoryResult extends Equatable {
  const MenuHistoryResult({
    required this.total,
    required this.limit,
    required this.offset,
    required this.menus,
  });

  final int total;
  final int limit;
  final int offset;
  final List<DailyMenu> menus;

  @override
  List<Object?> get props => [total, limit, offset, menus];
}
