// lib/models/git_project.dart
class GitProject {
  final int id;
  final int ownerId;
  final String name;
  final String url;
  final String username;
  final String privateKey;
  final String accessToken;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  GitProject({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.url,
    required this.username,
    required this.privateKey,
    required this.accessToken,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GitProject.fromJson(Map<String, dynamic> json) {
    return GitProject(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      url: json['url'],
      username: json['username'],
      privateKey: json['private_key'],
      accessToken: json['access_token'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'url': url,
      'username': username,
      'private_key': privateKey,
      'access_token': accessToken,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GitProject copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? url,
    String? username,
    String? privateKey,
    String? accessToken,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GitProject(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      url: url ?? this.url,
      username: username ?? this.username,
      privateKey: privateKey ?? this.privateKey,
      accessToken: accessToken ?? this.accessToken,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
