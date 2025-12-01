class ApiConstants {
  // Base URL for API endpoints
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const String baseUrl = 'http://10.10.0.159:5000/api';

  // Timeout durations
  static const Duration requestTimeout = Duration(seconds: 15);

  // API endpoints
  static const String authLogin = 'auth/login';
  static const String authRefresh = 'auth/refresh';
  static const String usersMe = 'users/me';
  static const String usersMePassword = 'users/me/password';
  static const String devices = 'devices/';
  static const String groups = 'groups/';

  ApiConstants._();
}
