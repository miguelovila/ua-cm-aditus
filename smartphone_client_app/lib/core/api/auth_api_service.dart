import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartphone_client_app/core/constants/api_constants.dart';

class AuthApiService {
  /// Login with email and password
  /// Returns the response containing tokens and user data
  /// Throws exception on failure
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.authLogin}',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      // Extract error message from backend response
      String errorMessage = 'Request failed';

      if (body.containsKey('error')) {
        errorMessage = body['error'] as String;
      } else if (body.containsKey('message')) {
        errorMessage = body['message'] as String;
      } else if (body.containsKey('msg')) {
        errorMessage = body['msg'] as String;
      }

      throw Exception(errorMessage);
    }
  }

  /// Refresh access token using refresh token
  /// Returns new access token
  /// Throws exception on failure
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/${ApiConstants.authRefresh}',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $refreshToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        )
        .timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      // Extract error message
      String errorMessage = 'Request failed';
      if (body.containsKey('error')) {
        errorMessage = body['error'] as String;
      } else if (body.containsKey('message')) {
        errorMessage = body['message'] as String;
      }
      throw Exception(errorMessage);
    }
  }
}
