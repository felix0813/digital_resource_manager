// lib/models/file_with_versions.dart
class FileVersion {
  final String id;
  final String versionId;
  final int size;
  final DateTime timestamp;

  FileVersion({
    required this.id,
    required this.versionId,
    required this.size,
    required this.timestamp,
  });

  factory FileVersion.fromJson(Map<String, dynamic> json) {
    return FileVersion(
      id: json['id'] as String,
      versionId: json['version_id'] as String,
      size: json['size'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version_id': versionId,
      'size': size,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class FileWithVersions {
  final String id;
  final String bucketName;
  final String objectName;
  final int size;
  final String latestVersion;
  final List<FileVersion> versions;
  final DateTime timestamp;

  FileWithVersions({
    required this.id,
    required this.bucketName,
    required this.objectName,
    required this.size,
    required this.latestVersion,
    required this.versions,
    required this.timestamp,
  });

  factory FileWithVersions.fromJson(Map<String, dynamic> json) {
    var versionsList = json['versions'] as List;
    List<FileVersion> versions = versionsList
        .map((version) => FileVersion.fromJson(version as Map<String, dynamic>))
        .toList();

    return FileWithVersions(
      id: json['id'] as String,
      bucketName: json['bucket_name'] as String,
      objectName: json['object_name'] as String,
      size: json['size'] as int,
      latestVersion: json['latest_version'] as String,
      versions: versions,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bucket_name': bucketName,
      'object_name': objectName,
      'size': size,
      'latest_version': latestVersion,
      'versions': versions.map((version) => version.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
