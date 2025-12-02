import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../../data/models/user_create_request.dart';
import '../../data/repositories/admin_user_repository.dart';

class CreateUserUseCase {
  final AdminUserRepository _repository;

  CreateUserUseCase(this._repository);

  Future<User> call(UserCreateRequest request) async {
    return await _repository.createUser(request);
  }
}
