import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../../data/models/group_create_request.dart';
import '../../data/repositories/admin_group_repository.dart';

class CreateGroupUseCase {
  final AdminGroupRepository _repository;

  CreateGroupUseCase(this._repository);

  Future<Group> call(GroupCreateRequest request) async {
    return await _repository.createGroup(request);
  }
}
