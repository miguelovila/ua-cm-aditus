import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_update_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';

class UpdateDoorUseCase {
  final AdminDoorRepository _repository;

  UpdateDoorUseCase(this._repository);

  Future<Door> call(int doorId, DoorUpdateRequest request) async {
    return await _repository.updateDoor(doorId, request);
  }
}
