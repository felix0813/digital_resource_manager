// lib/logic/file_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/file_item.dart';
import 'auth_service.dart';

class FileService {
  final String baseUrl = Environment.fileServiceUrl;
  final AuthService _authService = AuthService();

  Future<http.Response> uploadFile(File file, String token) async {
    final url = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
    );
    request.files.add(multipartFile);

    final response = await request.send();
    return await http.Response.fromStream(response);
  }

  Future<http.Response> downloadFile(String objectName, String token, {String? versionId}) async {
    final uri = Uri.parse('$baseUrl/download')
        .replace(queryParameters: {
          'object_name': objectName,
          if (versionId != null) 'version_id': versionId,
        });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }


  Future<http.Response> deleteFile(String objectName, String token, {String? versionId}) async {
    final uri = Uri.parse('$baseUrl/delete')
        .replace(queryParameters: {
          'object_name': objectName,
          if (versionId != null) 'version_id': versionId,
        });

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> healthCheck() async {
    final url = Uri.parse('${Environment.fileServiceBaseUrl}/health');
    return await http.get(url);
  }

  // 使用 AuthService 执行认证请求的便捷方法
  Future<http.Response?> uploadFileWithAuth(File file) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => uploadFile(file, token),
    );
  }

  Future<http.Response?> downloadFileWithAuth(String objectName, {String? versionId}) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => downloadFile(objectName, token, versionId: versionId),
    );
  }

  Future<http.Response?> deleteFileWithAuth(String objectName, {String? versionId}) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => deleteFile(objectName, token, versionId: versionId),
    );
  }

  Future<List<FileWithVersions>> listFilesWithVersions(String token) async {
    final url = Uri.parse('$baseUrl/list');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> objects = data['files'] as List<dynamic>;
      return objects
          .map((e) => FileWithVersions.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load files with versions: ${response.statusCode} - ${response.body}');
    }
  }

// 添加对应的认证版本方法
  Future<List<FileWithVersions>?> listFilesWithVersionsWithAuth() {
    return _authService.makeAuthenticatedRequest<List<FileWithVersions>>(
          (token) => listFilesWithVersions(token),
    );
  }
}

