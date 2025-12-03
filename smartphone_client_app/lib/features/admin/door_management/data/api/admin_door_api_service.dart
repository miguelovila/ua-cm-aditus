import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_create_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_update_request.dart';

class AdminDoorApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Get all doors (admin only)
  /// Endpoint: GET /api/doors/?include_inactive=true
  Future<List<Door>> getAllDoors() async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    // Add query parameter to include inactive doors for admin
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}?include_inactive=true',
    );
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
      final doorsJson = List<Map<String, dynamic>>.from(body['doors']);
      return doorsJson.map((json) => Door.fromJson(json)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch doors');
    }
  }

  /// Create a new door
  /// Endpoint: POST /api/doors/
  Future<Door> createDoor(DoorCreateRequest request) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/${ApiConstants.doors}');
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

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return Door.fromJson(body['door']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to create door');
    }
  }

  /// Get door by ID
  /// Endpoint: GET /api/doors/:id
  Future<Door> getDoorById(int doorId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId',
    );
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
      return Door.fromJson(body['door']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch door');
    }
  }

  /// Update door
  /// Endpoint: PUT /api/doors/:id
  Future<Door> updateDoor(int doorId, DoorUpdateRequest request) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId',
    );
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
      return Door.fromJson(body['door']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update door');
    }
  }

  /// Delete door
  /// Endpoint: DELETE /api/doors/:id
  Future<void> deleteDoor(int doorId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId',
    );
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
      throw Exception(body['error'] ?? 'Failed to delete door');
    }
  }
}
