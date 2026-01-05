import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'crypto_service.dart';
import 'secure_storage_service.dart';

class PairingService {
  static final PairingService _instance = PairingService._internal();
  factory PairingService() => _instance;
  PairingService._internal();

  final _cryptoService = CryptoService();
  final _storageService = SecureStorageService();

  static const String baseUrl = 'https://aditus-api.mxv.pt/api';

  Future<void> completePairing({
    required String code,
    required String deviceName,
  }) async {
    try {
      _log('Starting pairing with code: $code');

      bool hasKeys = await _cryptoService.hasStoredKeys();
      if (!hasKeys) {
        _log('Generating RSA key pair...');
        await _cryptoService.generateKeyPair();
      }

      final publicKey = await _cryptoService.getPublicKeyPEM();
      if (publicKey == null) {
        throw Exception('Failed to get public key');
      }

      _log('Sending pairing request to backend...');

      final url = Uri.parse('$baseUrl/devices/pairing/complete');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'device_name': deviceName,
          'public_key': publicKey,
        }),
      ).timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final deviceId = body['device']['id'].toString();
        final ownerId = body['device']['owner_id'].toString();

        await _storageService.saveDeviceId(deviceId);
        await _storageService.saveUserId(ownerId);

        _log('Pairing successful! Device ID: $deviceId, User ID: $ownerId');
      } else {
        final errorMessage = body['error'] ?? 'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _log('Pairing error: $e');
      rethrow;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[PairingService] $message');
    }
  }
}
