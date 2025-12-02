import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../../data/repositories/admin_group_repository.dart';

class GetAllGroupsUseCase {
  final AdminGroupRepository _repository;

  GetAllGroupsUseCase(this._repository);

  Future<List<Group>> call() async {
    return await _repository.getAllGroups();
  }
}
