// lib/logic/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../config/environment.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final Logger _logger = Logger('AuthService');

  /// 刷新访问令牌
  Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
    try {
      _logger.info('开始刷新访问令牌');
      final url = Uri.parse('${Environment.baseUrl}/refresh');
      _logger.fine('刷新令牌请求URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      _logger.fine('刷新令牌响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.info('令牌刷新成功');
        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'expires_in': data['expires_in'],
        };
      } else {
        _logger.warning('令牌刷新失败，状态码: ${response.statusCode}, 响应体: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.severe('刷新令牌时发生异常', e, stackTrace);
      return null;
    }
  }

  /// 获取有效的访问令牌，必要时自动刷新
  Future<String?> getValidToken() async {
    _logger.fine('开始获取有效访问令牌');
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');

    if (accessToken == null) {
      _logger.warning('未找到访问令牌');
    } else {
      _logger.fine('找到访问令牌');
    }

    if (refreshToken == null) {
      _logger.warning('未找到刷新令牌');
    } else {
      _logger.fine('找到刷新令牌');
    }

    // 这里可以添加检查访问令牌是否过期的逻辑
    // 为简化起见，我们假设当API返回401时令牌已过期

    return accessToken;
  }

  /// 刷新并保存新的令牌对
  Future<Map<String, String>?> refreshAndSaveTokens() async {
    _logger.info('开始刷新并保存令牌');
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      _logger.warning('未找到刷新令牌，无法刷新访问令牌');
      return null;
    }

    _logger.fine('使用刷新令牌刷新访问令牌');
    final tokenData = await refreshAccessToken(refreshToken);
    if (tokenData != null) {
      _logger.fine('令牌刷新成功，保存新令牌');
      // 保存新令牌
      await prefs.setString('access_token', tokenData['access_token']!);
      await prefs.setString('refresh_token', tokenData['refresh_token']!);

      _logger.info('新令牌保存成功');
      return {
        'access_token': tokenData['access_token'],
        'refresh_token': tokenData['refresh_token'],
      };
    } else {
      _logger.warning('令牌刷新失败');
    }

    return null;
  }

  /// 执行需要认证的请求，自动处理令牌过期和刷新
  Future<T?> makeAuthenticatedRequest<T>(
    Future<T> Function(String token) request,
  ) async {
    _logger.fine('开始执行认证请求');
    String? token = await getValidToken();
    if (token == null) {
      _logger.severe('未找到访问令牌，请先登录');
      throw Exception('未找到访问令牌，请先登录');
    }

    try {
      _logger.fine('使用访问令牌执行请求');
      return await request(token);
    } catch (e, stackTrace) {
      _logger.warning('请求执行失败，检查是否为认证错误', e, stackTrace);
      // 检查是否是认证错误
      if (_isAuthError(e)) {
        _logger.info('检测到认证错误，尝试刷新令牌');
        // 尝试刷新令牌
        final newTokens = await refreshAndSaveTokens();
        if (newTokens != null) {
          _logger.info('令牌刷新成功，使用新令牌重试请求');
          // 使用新令牌重试请求
          return await request(newTokens['access_token']!);
        } else {
          _logger.severe('令牌刷新失败，认证已过期');
          throw Exception('身份验证已过期，请重新登录');
        }
      }
      _logger.fine('非认证错误，重新抛出异常');
      rethrow;
    }
  }

  /// 判断是否为认证错误
  bool _isAuthError(dynamic error) {
    _logger.fine('检查是否为认证错误: $error');
    // 根据实际错误类型进行判断
    final errorString = error.toString().toLowerCase();
    final isAuthError = errorString.contains('401') ||
           errorString.contains('unauthorized') ||
           errorString.contains('authentication');

    _logger.fine('认证错误检查结果: $isAuthError');
    return isAuthError;
  }
}
