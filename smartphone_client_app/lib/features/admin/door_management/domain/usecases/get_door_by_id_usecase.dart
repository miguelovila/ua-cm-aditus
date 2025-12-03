import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';

class GetDoorByIdUseCase {
  final AdminDoorRepository _repository;

  GetDoorByIdUseCase(this._repository);

  Future<Door> call(int doorId) async {
    return await _repository.getDoorById(doorId);
  }
}
