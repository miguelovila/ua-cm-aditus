import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage Keys
  static const String _keyPinHash = 'pin_hash';
  static const String _keyPinSalt = 'pin_salt';
  static const String _keyPrivateKey = 'private_key';
  static const String _keyPublicKey = 'public_key';
  static const String _keyDeviceId = 'device_id';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyThemePreferences = 'theme_preferences';

  Future<void> savePinHash(String hash) async {
    await _storage.write(key: _keyPinHash, value: hash);
  }

  Future<String?> getPinHash() async {
    return await _storage.read(key: _keyPinHash);
  }

  Future<void> savePinSalt(String salt) async {
    await _storage.write(key: _keyPinSalt, value: salt);
  }

  Future<String?> getPinSalt() async {
    return await _storage.read(key: _keyPinSalt);
  }

  Future<void> savePrivateKey(String privateKey) async {
    await _storage.write(key: _keyPrivateKey, value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: _keyPrivateKey);
  }

  Future<void> savePublicKey(String publicKey) async {
    await _storage.write(key: _keyPublicKey, value: publicKey);
  }

  Future<String?> getPublicKey() async {
    return await _storage.read(key: _keyPublicKey);
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: _keyDeviceId);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<bool> hasCompletedOnboarding() async {
    final pinHash = await getPinHash();
    final deviceId = await getDeviceId();
    return pinHash != null && deviceId != null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyBiometricEnabled);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _keyUserData, value: jsonString);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _keyUserData);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUserData() async {
    await _storage.delete(key: _keyUserData);
  }

  Future<void> saveThemePreferences(Map<String, dynamic> preferences) async {
    final jsonString = jsonEncode(preferences);
    await _storage.write(key: _keyThemePreferences, value: jsonString);
  }

  Future<Map<String, dynamic>?> getThemePreferences() async {
    final jsonString = await _storage.read(key: _keyThemePreferences);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
