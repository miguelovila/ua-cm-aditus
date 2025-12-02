import '../../data/repositories/admin_group_repository.dart';

class AddMembersUseCase {
  final AdminGroupRepository _repository;

  AddMembersUseCase(this._repository);

  Future<void> call(int groupId, List<int> userIds) async {
    await _repository.addMembers(groupId, userIds);
  }
}
