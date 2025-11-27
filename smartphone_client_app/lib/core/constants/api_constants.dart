class ApiConstants {
  // Base URL for API endpoints
  static const String baseUrl = 'http://10.159.154.102:5000/api';

  // Timeout durations
  static const Duration requestTimeout = Duration(seconds: 15);

  // API endpoints
  static const String authLogin = 'auth/login';
  static const String authRefresh = 'auth/refresh';
  static const String usersMe = 'users/me';
  static const String devices = 'devices/';

  ApiConstants._();
}
