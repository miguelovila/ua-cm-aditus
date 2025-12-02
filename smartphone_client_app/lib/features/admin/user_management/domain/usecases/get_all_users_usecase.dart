import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../../data/repositories/admin_user_repository.dart';

class GetAllUsersUseCase {
  final AdminUserRepository _repository;

  GetAllUsersUseCase(this._repository);

  Future<List<User>> call() async {
    return await _repository.getAllUsers();
  }
}
