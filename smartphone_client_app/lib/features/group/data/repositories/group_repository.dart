import '../models/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getMyGroups();
}
