import '../../../../core/api/device_api_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/device.dart';
import 'device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceApiService _deviceApiService;
  final SecureStorageService _storageService;

  DeviceRepositoryImpl({
    DeviceApiService? deviceApiService,
    SecureStorageService? storageService,
  }) : _deviceApiService = deviceApiService ?? DeviceApiService(),
       _storageService = storageService ?? SecureStorageService();

  @override
  Future<List<Device>> getMyDevices() async {
    try {
      return await _deviceApiService.getMyDevices();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> registerDevice({
    required String deviceName,
    required String publicKey,
  }) async {
    try {
      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      final response = await _deviceApiService.registerDevice(
        deviceName: deviceName,
        publicKey: publicKey,
        accessToken: accessToken,
      );

      // Backend returns: { device: { id: ..., ... }, message: "..." }
      final deviceData = response['device'] as Map<String, dynamic>;
      final deviceId = deviceData['id'] as int;

      await _storageService.saveDeviceId(deviceId.toString());
      return deviceId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteDevice(int deviceId) async {
    try {
      await _deviceApiService.deleteDevice(deviceId);
    } catch (e) {
      rethrow;
    }
  }
}
