// lib/config/environment.dart
class Environment {
  static const String baseUrl = String.fromEnvironment(
    'USER_API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  static const String fileServiceBaseUrl = String.fromEnvironment(
    'FILE_SERVICE_BASE_URL',
    defaultValue: 'http://localhost:8082',
  );

  static const String pwdServiceBaseUrl = String.fromEnvironment(
    'PWD_SERVICE_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';
  static const String storageEndpoint = '/storage';

  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get fileServiceUrl => '$fileServiceBaseUrl$storageEndpoint';
}
