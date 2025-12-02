import '../../data/repositories/admin_group_repository.dart';

class RemoveMemberUseCase {
  final AdminGroupRepository _repository;

  RemoveMemberUseCase(this._repository);

  Future<void> call(int groupId, int userId) async {
    await _repository.removeMember(groupId, userId);
  }
}
