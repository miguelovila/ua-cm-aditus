import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';

class DeleteDoorUseCase {
  final AdminDoorRepository _repository;

  DeleteDoorUseCase(this._repository);

  Future<void> call(int doorId) async {
    await _repository.deleteDoor(doorId);
  }
}
