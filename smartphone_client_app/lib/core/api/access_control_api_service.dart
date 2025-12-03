import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';

class AccessRule {
  final List<SimpleUser> allowedUsers;
  final List<SimpleGroup> allowedGroups;
  final List<SimpleUser> exceptionUsers;
  final List<SimpleGroup> exceptionGroups;

  AccessRule({
    required this.allowedUsers,
    required this.allowedGroups,
    required this.exceptionUsers,
    required this.exceptionGroups,
  });

  factory AccessRule.fromJson(Map<String, dynamic> json) {
    return AccessRule(
      allowedUsers: (json['allowed_users'] as List)
          .map((u) => SimpleUser.fromJson(u))
          .toList(),
      allowedGroups: (json['allowed_groups'] as List)
          .map((g) => SimpleGroup.fromJson(g))
          .toList(),
      exceptionUsers: (json['exception_users'] as List)
          .map((u) => SimpleUser.fromJson(u))
          .toList(),
      exceptionGroups: (json['exception_groups'] as List)
          .map((g) => SimpleGroup.fromJson(g))
          .toList(),
    );
  }
}

class SimpleUser {
  final int id;
  final String email;

  SimpleUser({required this.id, required this.email});

  factory SimpleUser.fromJson(Map<String, dynamic> json) {
    return SimpleUser(
      id: json['id'] as int,
      email: json['email'] as String,
    );
  }
}

class SimpleGroup {
  final int id;
  final String name;

  SimpleGroup({required this.id, required this.name});

  factory SimpleGroup.fromJson(Map<String, dynamic> json) {
    return SimpleGroup(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class AccessControlApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Get all access rules for a door
  /// Endpoint: GET /api/access_control/:door_id/access
  Future<AccessRule> getAccessRules(int doorId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access',
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
      return AccessRule.fromJson(body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch access rules');
    }
  }

  /// Grant user direct access to door
  /// Endpoint: POST /api/access_control/:door_id/access/users
  Future<void> grantUserAccess(int doorId, int userId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/users',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'user_id': userId}),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to grant user access');
    }
  }

  /// Revoke user direct access from door
  /// Endpoint: DELETE /api/access_control/:door_id/access/users/:user_id
  Future<void> revokeUserAccess(int doorId, int userId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/users/$userId',
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
      throw Exception(body['error'] ?? 'Failed to revoke user access');
    }
  }

  /// Grant group access to door
  /// Endpoint: POST /api/access_control/:door_id/access/groups
  Future<void> grantGroupAccess(int doorId, int groupId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/groups',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'group_id': groupId}),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to grant group access');
    }
  }

  /// Revoke group access from door
  /// Endpoint: DELETE /api/access_control/:door_id/access/groups/:group_id
  Future<void> revokeGroupAccess(int doorId, int groupId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/groups/$groupId',
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
      throw Exception(body['error'] ?? 'Failed to revoke group access');
    }
  }

  /// Add user to blacklist (exception)
  /// Endpoint: POST /api/access_control/:door_id/access/exceptions/users
  Future<void> addUserException(int doorId, int userId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/exceptions/users',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'user_id': userId}),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to add user exception');
    }
  }

  /// Remove user from blacklist (exception)
  /// Endpoint: DELETE /api/access_control/:door_id/access/exceptions/users/:user_id
  Future<void> removeUserException(int doorId, int userId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/exceptions/users/$userId',
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
      throw Exception(body['error'] ?? 'Failed to remove user exception');
    }
  }

  /// Add group to blacklist (exception)
  /// Endpoint: POST /api/access_control/:door_id/access/exceptions/groups
  Future<void> addGroupException(int doorId, int groupId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/exceptions/groups',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'group_id': groupId}),
        )
        .timeout(ApiConstants.requestTimeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to add group exception');
    }
  }

  /// Remove group from blacklist (exception)
  /// Endpoint: DELETE /api/access_control/:door_id/access/exceptions/groups/:group_id
  Future<void> removeGroupException(int doorId, int groupId) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.doors}$doorId/access/exceptions/groups/$groupId',
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
      throw Exception(body['error'] ?? 'Failed to remove group exception');
    }
  }
}
