// lib/models/password_item.dart
class PasswordItem {
  final int id;
  final int ownerId;
  final String userName;
  final String password;
  final String? website;
  final String? description;
  final String createdAt;
  final String updatedAt;

  PasswordItem({
    required this.id,
    required this.ownerId,
    required this.userName,
    required this.password,
    this.website,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'] as int? ?? 0,
      ownerId: json['owner_id'] as int? ?? 0,
      userName: json['user_name'] as String? ?? '',
      password: json['password'] as String? ?? '',
      website: json['website'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'user_name': userName,
      'password': password,
      'website': website,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
