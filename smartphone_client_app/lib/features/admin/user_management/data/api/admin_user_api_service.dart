import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../models/user_create_request.dart';
import '../models/user_update_request.dart';

class AdminUserApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Get all users (admin only)
  /// Endpoint: GET /api/users/
  Future<List<User>> getAllUsers() async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/users/');

    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final usersJson = List<Map<String, dynamic>>.from(body['users']);
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch users');
    }
  }

  /// Create a new user (admin only)
  /// Endpoint: POST /api/users/
  Future<User> createUser(UserCreateRequest request) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/users/');

    print('DEBUG: Creating user at URL: $url');
    print('DEBUG: Request body: ${jsonEncode(request.toJson())}');

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(ApiConstants.requestTimeout);

    print('DEBUG: Response status: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return User.fromJson(body['user']);
    } else {
      // Try to parse as JSON first, fallback to raw body if HTML
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to create user');
      } catch (e) {
        throw Exception('API Error (${response.statusCode}): ${response.body.substring(0, 200)}...');
      }
    }
  }

  /// Get user details by ID
  /// Endpoint: GET /api/users/:id
  Future<User> getUserById(int userId) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/users/$userId');

    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return User.fromJson(body['user']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch user details');
    }
  }

  /// Update user details
  /// Endpoint: PUT /api/users/:id
  Future<User> updateUser(int userId, UserUpdateRequest request) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/users/$userId');

    final response = await http
        .put(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return User.fromJson(body['user']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update user');
    }
  }

  /// Delete a user
  /// Endpoint: DELETE /api/users/:id
  Future<void> deleteUser(int userId) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/users/$userId');

    final response = await http
        .delete(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete user');
    }
  }
}
