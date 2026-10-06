import 'package:equatable/equatable.dart';

class CounterLineItem extends Equatable {
  const CounterLineItem({
    required this.id,
    required this.name,
    this.unit = 'Nos',
    this.category = 'Main',
    this.quantity = 1,
  });

  final String id;
  final String name;
  final String unit;
  final String category;
  final double quantity;

  @override
  List<Object?> get props => [id, name, unit, category, quantity];
}
