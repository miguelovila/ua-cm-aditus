import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'secure_storage_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = SecureStorageService();

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      _log('Can check biometrics: $canCheck');
      return canCheck;
    } on PlatformException catch (e) {
      _log('Error checking biometrics: $e');
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      _log('Device supported: $isSupported');
      return isSupported;
    } on PlatformException catch (e) {
      _log('Error checking device support: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      _log('Available biometrics: $availableBiometrics');
      return availableBiometrics;
    } on PlatformException catch (e) {
      _log('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    _log('Starting biometric authentication');

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
          ),
        ],
      );

      _log('Authentication result: $didAuthenticate');
      return didAuthenticate;
    } on LocalAuthException catch (e) {
      _log('LocalAuth exception: ${e.code}');

      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          _log('User canceled authentication');
          break;
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          _log('Biometric auth not available');
          break;
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          _log('User has not enrolled biometrics');
          break;
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          _log('Too many failed attempts - temporarily locked');
          break;
        default:
          _log('LocalAuth error: ${e.code}');
      }

      return false;
    } on PlatformException catch (e) {
      _log('Platform error: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'NotAvailable':
          _log('Biometric auth not available on this device');
          break;
        case 'NotEnrolled':
          _log('User has not enrolled biometrics');
          break;
        case 'LockedOut':
          _log('Too many failed attempts - temporarily locked');
          break;
        case 'PermanentlyLockedOut':
          _log('Permanently locked - requires device unlock');
          break;
        default:
          _log('Unknown platform error: ${e.code}');
      }

      return false;
    } catch (e) {
      _log('Unexpected error during authentication: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.isBiometricEnabled();
    _log('Biometric enabled preference: $enabled');
    return enabled;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _log('Setting biometric enabled: $enabled');
    await _storage.setBiometricEnabled(enabled);
  }

  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }

    return 'Biometric Authentication';
  }

  Future<String> getBiometricIconName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'face';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'iris';
    }

    return 'fingerprint'; // Default
  }

  Future<bool> shouldUseBiometrics() async {
    final canUse = await canCheckBiometrics();
    final isEnabled = await isBiometricEnabled();
    final result = canUse && isEnabled;
    _log(
      'Should use biometrics: $result (canUse: $canUse, enabled: $isEnabled)',
    );
    return result;
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[BiometricService] $message');
    }
  }
}
