import '../../data/repositories/admin_group_repository.dart';

class DeleteGroupUseCase {
  final AdminGroupRepository _repository;

  DeleteGroupUseCase(this._repository);

  Future<void> call(int groupId) async {
    await _repository.deleteGroup(groupId);
  }
}
