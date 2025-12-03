import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';

class GetAllDoorsUseCase {
  final AdminDoorRepository _repository;

  GetAllDoorsUseCase(this._repository);

  Future<List<Door>> call() async {
    return await _repository.getAllDoors();
  }
}
