import '../../data/models/group.dart';
import '../../data/repositories/group_repository.dart';

class GetGroupsUseCase {
  final GroupRepository _repository;

  GetGroupsUseCase(this._repository);

  Future<List<Group>> call() async {
    return await _repository.getMyGroups();
  }
}
