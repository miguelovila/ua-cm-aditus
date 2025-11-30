import '../models/device.dart';

abstract class DeviceRepository {
  Future<List<Device>> getMyDevices();
  Future<int> registerDevice({
    required String deviceName,
    required String publicKey,
  });
  Future<void> deleteDevice(int deviceId);
}
