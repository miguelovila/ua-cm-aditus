import '../../data/repositories/device_repository.dart';

class DeleteDeviceUseCase {
  final DeviceRepository _repository;

  DeleteDeviceUseCase(this._repository);

  Future<void> call(int deviceId) async {
    return await _repository.deleteDevice(deviceId);
  }
}
