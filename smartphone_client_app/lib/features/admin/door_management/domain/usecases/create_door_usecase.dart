import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_create_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';

class CreateDoorUseCase {
  final AdminDoorRepository _repository;

  CreateDoorUseCase(this._repository);

  Future<Door> call(DoorCreateRequest request) async {
    return await _repository.createDoor(request);
  }
}
