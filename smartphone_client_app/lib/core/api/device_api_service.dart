import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/features/device/data/models/device.dart';

class DeviceApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Delete/deregister a device
  /// Throws exception on failure
  Future<void> deleteDevice(int deviceId) async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.devices}$deviceId',
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

    if (response.statusCode == 200) {
      return; // Success
    } else if (response.statusCode == 404) {
      throw Exception('Device not found');
    } else if (response.statusCode == 403) {
      throw Exception('Access denied');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete device');
    }
  }

  /// Get current user's devices
  Future<List<Device>> getMyDevices() async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.devices}my-devices',
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
      final devicesJson = List<Map<String, dynamic>>.from(body['devices']);
      return devicesJson.map((json) => Device.fromJson(json)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch devices');
    }
  }

  /// Register a new device
  /// Returns the response containing device data
  /// Throws exception on failure
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String publicKey,
    required String accessToken,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.devices}',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': deviceName,
            'public_key': publicKey,
          }),
        )
        .timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = 'Request failed';
      if (body.containsKey('error')) {
        errorMessage = body['error'] as String;
      } else if (body.containsKey('message')) {
        errorMessage = body['message'] as String;
      }
      throw Exception(errorMessage);
    }
  }

  /// Initiate smartwatch pairing and get pairing code
  Future<Map<String, dynamic>> initiateSmartwatchPairing() async {
    final accessToken = await _secureStorage.getAccessToken();

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.devices}pairing/initiate',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        )
        .timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = 'Failed to initiate pairing';
      if (body.containsKey('error')) {
        errorMessage = body['error'] as String;
      }
      throw Exception(errorMessage);
    }
  }
}
