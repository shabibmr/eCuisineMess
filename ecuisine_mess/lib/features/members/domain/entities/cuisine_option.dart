import 'package:equatable/equatable.dart';

/// Lightweight cuisine row for member form dropdowns.
class CuisineOption extends Equatable {
  const CuisineOption({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, isActive];
}
