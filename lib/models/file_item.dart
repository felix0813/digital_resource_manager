// lib/models/file_item.dart
class FileItem {
  final String name;
  final int size;
  final DateTime? lastModified;
  final String contentType;
  final String versionId;

  FileItem({
    required this.name,
    required this.size,
    this.lastModified,
    required this.contentType,
    required this.versionId,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      size: json['size'] as int,
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'] as String)
          : null,
      contentType: json['content_type'] as String,
      versionId: json['version_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'last_modified': lastModified?.toIso8601String(),
      'content_type': contentType,
      'version_id': versionId,
    };
  }
}
