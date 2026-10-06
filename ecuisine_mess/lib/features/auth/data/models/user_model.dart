import 'package:ecuisine_mess/features/auth/domain/entities/app_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.isActive = true,
  });

  final String id;
  final String username;
  final String displayName;
  final bool isActive;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['username']?.toString() ??
          '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  AppUser toEntity() => AppUser(
        id: id,
        username: username,
        displayName: displayName,
        isActive: isActive,
      );
}
