import 'package:equatable/equatable.dart';

/// Write payload for one menu line (save-day / save slot).
class DailyMenuItemInput extends Equatable {
  const DailyMenuItemInput({
    required this.itemId,
    this.quantity = 1.0,
    this.notes,
  });

  final String itemId;
  final double quantity;
  final String? notes;

  @override
  List<Object?> get props => [itemId, quantity, notes];
}
