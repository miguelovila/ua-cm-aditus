import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../models/group_create_request.dart';
import '../models/group_update_request.dart';

class AdminGroupApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Get all groups (admin only)
  /// Endpoint: GET /api/groups
  Future<List<Group>> getAllGroups() async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/${ApiConstants.groups}');

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
      final groupsJson = List<Map<String, dynamic>>.from(body['groups']);
      return groupsJson.map((json) => Group.fromJson(json)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch groups');
    }
  }

  /// Create a new group
  /// Endpoint: POST /api/groups
  Future<Group> createGroup(GroupCreateRequest request) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/${ApiConstants.groups}');

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
      return Group.fromJson(body['group']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to create group');
    }
  }

  /// Get group details by ID
  /// Endpoint: GET /api/groups/:id
  Future<Group> getGroupById(int groupId) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.groups}$groupId',
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
      return Group.fromJson(body['group']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch group details');
    }
  }

  /// Update group details
  /// Endpoint: PUT /api/groups/:id
  Future<Group> updateGroup(int groupId, GroupUpdateRequest request) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.groups}$groupId',
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
      return Group.fromJson(body['group']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update group');
    }
  }

  /// Delete a group
  /// Endpoint: DELETE /api/groups/:id
  Future<void> deleteGroup(int groupId) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.groups}$groupId',
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
      throw Exception(body['error'] ?? 'Failed to delete group');
    }
  }

  /// Add members to a group
  /// Endpoint: POST /api/groups/:id/members
  /// Request body: { "user_ids": [1, 2, 3] }
  Future<void> addMembers(int groupId, List<int> userIds) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.groups}$groupId/members',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'user_ids': userIds}),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to add members');
    }
  }

  /// Remove a member from a group
  /// Endpoint: DELETE /api/groups/:id/members/:user_id
  Future<void> removeMember(int groupId, int userId) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.groups}$groupId/members/$userId',
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
      throw Exception(body['error'] ?? 'Failed to remove member');
    }
  }
}
