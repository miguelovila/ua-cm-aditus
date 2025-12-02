import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../../data/models/group_update_request.dart';
import '../../data/repositories/admin_group_repository.dart';

class UpdateGroupUseCase {
  final AdminGroupRepository _repository;

  UpdateGroupUseCase(this._repository);

  Future<Group> call(int groupId, GroupUpdateRequest request) async {
    return await _repository.updateGroup(groupId, request);
  }
}
