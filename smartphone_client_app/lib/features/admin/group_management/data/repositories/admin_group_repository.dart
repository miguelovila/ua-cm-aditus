import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../models/group_create_request.dart';
import '../models/group_update_request.dart';

/// Repository interface for admin group operations
abstract class AdminGroupRepository {
  Future<List<Group>> getAllGroups();
  Future<Group> createGroup(GroupCreateRequest request);
  Future<Group> getGroupById(int groupId);
  Future<Group> updateGroup(int groupId, GroupUpdateRequest request);
  Future<void> deleteGroup(int groupId);
  Future<void> addMembers(int groupId, List<int> userIds);
  Future<void> removeMember(int groupId, int userId);
}
