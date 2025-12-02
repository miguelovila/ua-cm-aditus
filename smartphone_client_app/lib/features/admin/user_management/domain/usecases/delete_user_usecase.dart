import '../../data/repositories/admin_user_repository.dart';

class DeleteUserUseCase {
  final AdminUserRepository _repository;

  DeleteUserUseCase(this._repository);

  Future<void> call(int userId) async {
    await _repository.deleteUser(userId);
  }
}
