import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:smartphone_client_app/core/security/secure_storage_service.dart';

class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  final _storage = SecureStorageService();

  Future<void> setupPin(String pin) async {
    _log("Setting up new PIN");

    if (!_isValidPin(pin)) {
      throw ArgumentError('PIN must be 4-6 digits');
    }

    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _storage.savePinSalt(salt);
    await _storage.savePinHash(hash);

    _log("PIN setup complete");
  }

  Future<bool> verifyPin(String pin) async {
    _log("Verifying PIN");

    final storedSalt = await _storage.getPinSalt();
    final storedHash = await _storage.getPinHash();

    if (storedSalt == null || storedHash == null) {
      _log("No PIN set");
      return false;
    }

    final hash = _hashPin(pin, storedSalt);

    final isValid = hash == storedHash;
    _log(isValid ? "PIN verified successfully" : "PIN verification failed");
    return isValid;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    _log("Changing PIN");

    final isOldPinValid = await verifyPin(oldPin);
    if (!isOldPinValid) {
      _log("Old PIN is incorrect");
      return false;
    }

    await setupPin(newPin);
    _log("PIN changed successfully");

    return true;
  }

  Future<bool> isPinSetup() async {
    final hash = await _storage.getPinHash();
    return hash != null;
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);

    return base64Encode(digest.bytes);
  }

  bool _isValidPin(String pin) {
    final pinRegex = RegExp(r'^\d{4,6}$');
    return pinRegex.hasMatch(pin);
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[PinService] $message');
    }
  }
}
