// lib/logic/password_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'auth_service.dart';
import '../models/password_item.dart';

class PasswordService {
  final String baseUrl = Environment.pwdServiceBaseUrl;
  final AuthService _authService = AuthService();

  // 获取密码列表
  Future<http.Response> listPasswords(String token) async {
    final url = Uri.parse('$baseUrl/passwords');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // 创建新密码
  Future<http.Response> createPassword(PasswordItem password, String token) async {
    final url = Uri.parse('$baseUrl/passwords');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(password.toJson()),
    );
    return response;
  }

  // 更新密码
  Future<http.Response> updatePassword(PasswordItem password, String token) async {
    final url = Uri.parse('$baseUrl/passwords/${password.id}');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(password.toJson()),
    );
    return response;
  }

  Future<http.Response> updatePasswordMeta(PasswordItem password, String token) async {
    final url = Uri.parse('$baseUrl/passwords/${password.id}/meta');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(password.toJson()),
    );
    return response;
  }

  // 删除密码
  Future<http.Response> deletePassword(int id, String token) async {
    final url = Uri.parse('$baseUrl/passwords/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // 获取单个密码明文
  Future<http.Response> getPassword(int id, String token) async {
    final url = Uri.parse('$baseUrl/passwords/$id');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // 批量获取密码
  Future<http.Response> getMultiPasswords(List<int> ids, String token) async {
    final url = Uri.parse('$baseUrl/passwords/batch');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'ids': ids}),
    );
    return response;
  }

  // 使用 AuthService 执行认证请求的便捷方法
  Future<http.Response?> listPasswordsWithAuth() {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => listPasswords(token),
    );
  }

  Future<http.Response?> createPasswordWithAuth(PasswordItem password) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => createPassword(password, token),
    );
  }

  Future<http.Response?> updatePasswordWithAuth(PasswordItem password) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => updatePassword(password, token),
    );
  }
  Future<http.Response?> updatePasswordMetaWithAuth(PasswordItem password) {
    return _authService.makeAuthenticatedRequest<http.Response>(
          (token) => updatePasswordMeta(password, token),
    );
  }

  Future<http.Response?> deletePasswordWithAuth(int id) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => deletePassword(id, token),
    );
  }

  Future<http.Response?> getPasswordWithAuth(int id) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => getPassword(id, token),
    );
  }

  Future<http.Response?> getMultiPasswordsWithAuth(List<int> ids) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => getMultiPasswords(ids, token),
    );
  }
}
