import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String _baseUrl = ApiConstants.baseUrl;
  final http.Client _httpClient;
  static const Duration _timeout = ApiConstants.requestTimeout;

  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
    bool addArtificialDelay = false,
  }) async {
    if (addArtificialDelay) {
      final random = Random();
      final delay = Duration(milliseconds: 1000 + random.nextInt(2000));
      await Future.delayed(delay);
    }

    try {
      final url = Uri.parse('$_baseUrl/$endpoint');

      final headers = {'Content-Type': 'application/json'};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _httpClient
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        // Extract error message from backend response
        String errorMessage = 'Request failed';

        if (responseBody.containsKey('error')) {
          errorMessage = responseBody['error'] as String;
        } else if (responseBody.containsKey('message')) {
          errorMessage = responseBody['message'] as String;
        } else if (responseBody.containsKey('msg')) {
          errorMessage = responseBody['msg'] as String;
        }

        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } on TimeoutException {
      throw ApiException(
        'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      throw ApiException(
        'No internet connection. Please check your network settings.',
      );
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    bool addArtificialDelay = false,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$endpoint');

      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _httpClient
          .get(url, headers: headers)
          .timeout(_timeout);

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        // Extract error message
        String errorMessage = 'Request failed';
        if (responseBody.containsKey('error')) {
          errorMessage = responseBody['error'] as String;
        } else if (responseBody.containsKey('message')) {
          errorMessage = responseBody['message'] as String;
        }
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } on TimeoutException {
      throw ApiException('Request timed out. Please check your connection.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await post(
      ApiConstants.authLogin,
      body: {'email': email, 'password': password},
    );
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    return await post(ApiConstants.authRefresh, body: {}, token: refreshToken);
  }

  Future<Map<String, dynamic>> getCurrentUser({
    required String accessToken,
  }) async {
    return await get(ApiConstants.usersMe, token: accessToken);
  }

  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String publicKey,
    required String accessToken,
  }) async {
    return await post(
      ApiConstants.devices,
      body: {'name': deviceName, 'public_key': publicKey},
      token: accessToken,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
