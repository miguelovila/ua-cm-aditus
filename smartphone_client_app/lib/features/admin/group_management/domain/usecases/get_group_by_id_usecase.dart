import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../../data/repositories/admin_group_repository.dart';

class GetGroupByIdUseCase {
  final AdminGroupRepository _repository;

  GetGroupByIdUseCase(this._repository);

  Future<Group> call(int groupId) async {
    return await _repository.getGroupById(groupId);
  }
}
