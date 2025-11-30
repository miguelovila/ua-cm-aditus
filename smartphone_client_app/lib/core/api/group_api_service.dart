import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';

class GroupApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Get current user's groups
  Future<List<Group>> getMyGroups() async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.groups}my-groups',
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
      final groupsJson = List<Map<String, dynamic>>.from(body['groups']);
      return groupsJson.map((json) => Group.fromJson(json)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch groups');
    }
  }
}
