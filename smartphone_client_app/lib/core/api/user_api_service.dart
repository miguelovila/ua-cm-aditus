import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';

class UserApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Change user's password
  /// Throws exception on failure
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.usersMePassword}',
    );

    final response = await http
        .put(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode == 200) {
      return; // Success
    } else if (response.statusCode == 401) {
      throw Exception('Current password is incorrect');
    } else if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Missing required fields');
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to change password');
    }
  }
}
