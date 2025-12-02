import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../models/user_create_request.dart';
import '../models/user_update_request.dart';

/// Repository interface for admin user operations
abstract class AdminUserRepository {
  Future<List<User>> getAllUsers();
  Future<User> createUser(UserCreateRequest request);
  Future<User> getUserById(int userId);
  Future<User> updateUser(int userId, UserUpdateRequest request);
  Future<void> deleteUser(int userId);
}
