import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../../data/models/user_update_request.dart';
import '../../data/repositories/admin_user_repository.dart';

class UpdateUserUseCase {
  final AdminUserRepository _repository;

  UpdateUserUseCase(this._repository);

  Future<User> call(int userId, UserUpdateRequest request) async {
    return await _repository.updateUser(userId, request);
  }
}
