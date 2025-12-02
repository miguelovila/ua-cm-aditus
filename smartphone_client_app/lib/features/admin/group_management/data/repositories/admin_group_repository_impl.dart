import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../api/admin_group_api_service.dart';
import '../models/group_create_request.dart';
import '../models/group_update_request.dart';
import 'admin_group_repository.dart';

class AdminGroupRepositoryImpl implements AdminGroupRepository {
  final AdminGroupApiService _apiService;

  AdminGroupRepositoryImpl({AdminGroupApiService? apiService})
      : _apiService = apiService ?? AdminGroupApiService();

  @override
  Future<List<Group>> getAllGroups() async {
    try {
      return await _apiService.getAllGroups();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Group> createGroup(GroupCreateRequest request) async {
    try {
      return await _apiService.createGroup(request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Group> getGroupById(int groupId) async {
    try {
      return await _apiService.getGroupById(groupId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Group> updateGroup(int groupId, GroupUpdateRequest request) async {
    try {
      return await _apiService.updateGroup(groupId, request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(int groupId) async {
    try {
      await _apiService.deleteGroup(groupId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addMembers(int groupId, List<int> userIds) async {
    try {
      await _apiService.addMembers(groupId, userIds);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeMember(int groupId, int userId) async {
    try {
      await _apiService.removeMember(groupId, userId);
    } catch (e) {
      rethrow;
    }
  }
}
