import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_create_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_update_request.dart';

abstract class AdminDoorRepository {
  Future<List<Door>> getAllDoors();
  Future<Door> createDoor(DoorCreateRequest request);
  Future<Door> getDoorById(int doorId);
  Future<Door> updateDoor(int doorId, DoorUpdateRequest request);
  Future<void> deleteDoor(int doorId);
}
