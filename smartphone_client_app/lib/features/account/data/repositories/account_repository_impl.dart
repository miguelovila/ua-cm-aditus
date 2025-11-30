import '../../../../core/api/device_api_service.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import 'account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final BiometricService _biometricService;
  final DeviceApiService _deviceApiService;
  final SecureStorageService _storageService;

  AccountRepositoryImpl({
    BiometricService? biometricService,
    DeviceApiService? deviceApiService,
    SecureStorageService? storageService,
  }) : _biometricService = biometricService ?? BiometricService(),
       _deviceApiService = deviceApiService ?? DeviceApiService(),
       _storageService = storageService ?? SecureStorageService();

  @override
  Future<bool> areBiometricsAvailable() async {
    return await _biometricService.canCheckBiometrics();
  }

  @override
  Future<String> getBiometricTypeName() async {
    return await _biometricService.getBiometricTypeName();
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _biometricService.setBiometricEnabled(enabled);
  }

  @override
  Future<bool> authenticateWithBiometrics({required String reason}) async {
    return await _biometricService.authenticate(reason: reason);
  }

  @override
  Future<void> logout() async {
    // Deregister device from API
    final deviceIdStr = await _storageService.getDeviceId();
    if (deviceIdStr != null) {
      final deviceId = int.tryParse(deviceIdStr);
      if (deviceId != null) {
        try {
          await _deviceApiService.deleteDevice(deviceId);
        } catch (e) {
          // Continue logout even if API call fails
        }
      }
    }

    // Clear all stored data
    await _storageService.clearAll();
  }
}
