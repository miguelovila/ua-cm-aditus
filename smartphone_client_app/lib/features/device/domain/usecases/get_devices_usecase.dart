import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';

class GetDevicesUseCase {
  final DeviceRepository _repository;

  GetDevicesUseCase(this._repository);

  Future<List<Device>> call() async {
    return await _repository.getMyDevices();
  }
}
