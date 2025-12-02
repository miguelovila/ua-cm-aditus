import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../../data/repositories/admin_user_repository.dart';

class GetUserByIdUseCase {
  final AdminUserRepository _repository;

  GetUserByIdUseCase(this._repository);

  Future<User> call(int userId) async {
    return await _repository.getUserById(userId);
  }
}
