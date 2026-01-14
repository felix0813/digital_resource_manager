// lib/logic/git_project_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import 'auth_service.dart';
import '../models/git_project.dart';

class GitProjectService {
  final String baseUrl = Environment.gitServiceBaseUrl;
  final AuthService _authService = AuthService();

  // 获取项目列表
  Future<http.Response> listProjects(String token) async {
    final url = Uri.parse('$baseUrl/git-projects/list');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // 创建新项目
  Future<http.Response> createProject(GitProject project, String token) async {
    final url = Uri.parse('$baseUrl/git-projects/create');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(project.toJson()),
    );
    return response;
  }

  // 更新项目
  Future<http.Response> updateProject(GitProject project, String token) async {
    final url = Uri.parse('$baseUrl/git-projects/${project.id}');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(project.toJson()),
    );
    return response;
  }

  // 删除项目
  Future<http.Response> deleteProject(int id, String token) async {
    final url = Uri.parse('$baseUrl/git-projects/$id');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // 获取单个项目
  Future<http.Response> getProject(int id, String token) async {
    final url = Uri.parse('$baseUrl/git-projects/$id');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // 使用 AuthService 执行认证请求的便捷方法
  Future<http.Response?> listProjectsWithAuth() {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => listProjects(token),
    );
  }

  Future<http.Response?> createProjectWithAuth(GitProject project) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => createProject(project, token),
    );
  }

  Future<http.Response?> updateProjectWithAuth(GitProject project) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => updateProject(project, token),
    );
  }

  Future<http.Response?> deleteProjectWithAuth(int id) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => deleteProject(id, token),
    );
  }

  Future<http.Response?> getProjectWithAuth(int id) {
    return _authService.makeAuthenticatedRequest<http.Response>(
      (token) => getProject(id, token),
    );
  }
}
