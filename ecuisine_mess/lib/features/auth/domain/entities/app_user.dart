import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.isActive = true,
  });

  final String id;
  final String username;
  final String displayName;
  final bool isActive;

  @override
  List<Object?> get props => [id, username, displayName, isActive];
}
