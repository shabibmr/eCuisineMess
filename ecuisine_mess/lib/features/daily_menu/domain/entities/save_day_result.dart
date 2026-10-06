import 'package:equatable/equatable.dart';

class SaveDayResult extends Equatable {
  const SaveDayResult({
    required this.success,
    required this.menuDate,
    required this.savedSlotsCount,
    this.message,
  });

  final bool success;
  final String menuDate;
  final int savedSlotsCount;
  final String? message;

  @override
  List<Object?> get props => [success, menuDate, savedSlotsCount, message];
}
