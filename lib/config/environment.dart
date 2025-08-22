// lib/config/environment.dart
class Environment {
  static const String baseUrl = String.fromEnvironment(
    'USER_API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';

  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get loginUrl => '$baseUrl$loginEndpoint';
}
