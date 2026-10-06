class AppUser {
  final String id;
  final String username;
  final String displayName;
  final bool isActive;

  AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.isActive = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? json['username']?.toString() ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}
