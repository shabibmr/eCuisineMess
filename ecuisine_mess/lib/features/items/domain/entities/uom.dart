import 'package:equatable/equatable.dart';

class Uom extends Equatable {
  const Uom({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}
