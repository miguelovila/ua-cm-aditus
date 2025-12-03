import 'package:smartphone_client_app/features/admin/door_management/data/api/admin_door_api_service.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_create_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_update_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';

class AdminDoorRepositoryImpl implements AdminDoorRepository {
  final AdminDoorApiService _apiService;

  AdminDoorRepositoryImpl({AdminDoorApiService? apiService})
      : _apiService = apiService ?? AdminDoorApiService();

  @override
  Future<List<Door>> getAllDoors() async {
    try {
      return await _apiService.getAllDoors();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Door> createDoor(DoorCreateRequest request) async {
    try {
      return await _apiService.createDoor(request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Door> getDoorById(int doorId) async {
    try {
      return await _apiService.getDoorById(doorId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Door> updateDoor(int doorId, DoorUpdateRequest request) async {
    try {
      return await _apiService.updateDoor(doorId, request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteDoor(int doorId) async {
    try {
      await _apiService.deleteDoor(doorId);
    } catch (e) {
      rethrow;
    }
  }
}
