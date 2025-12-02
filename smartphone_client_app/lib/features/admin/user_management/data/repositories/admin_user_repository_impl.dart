import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../api/admin_user_api_service.dart';
import '../models/user_create_request.dart';
import '../models/user_update_request.dart';
import 'admin_user_repository.dart';

class AdminUserRepositoryImpl implements AdminUserRepository {
  final AdminUserApiService _apiService;

  AdminUserRepositoryImpl({AdminUserApiService? apiService})
      : _apiService = apiService ?? AdminUserApiService();

  @override
  Future<List<User>> getAllUsers() async {
    try {
      return await _apiService.getAllUsers();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> createUser(UserCreateRequest request) async {
    try {
      return await _apiService.createUser(request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> getUserById(int userId) async {
    try {
      return await _apiService.getUserById(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> updateUser(int userId, UserUpdateRequest request) async {
    try {
      return await _apiService.updateUser(userId, request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(int userId) async {
    try {
      await _apiService.deleteUser(userId);
    } catch (e) {
      rethrow;
    }
  }
}
