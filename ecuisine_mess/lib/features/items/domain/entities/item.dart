import 'package:equatable/equatable.dart';

class Item extends Equatable {
  const Item({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName = '',
    this.uomId,
    this.uomName = 'Nos',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String categoryName;
  final String? uomId;
  final String uomName;
  final bool isActive;

  String get unit => uomName;

  @override
  List<Object?> get props =>
      [id, name, categoryId, categoryName, uomId, uomName, isActive];
}
