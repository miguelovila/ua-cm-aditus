import '../../../../core/api/group_api_service.dart';
import '../models/group.dart';
import 'group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupApiService _apiService;

  GroupRepositoryImpl({GroupApiService? apiService})
    : _apiService = apiService ?? GroupApiService();

  @override
  Future<List<Group>> getMyGroups() async {
    try {
      return await _apiService.getMyGroups();
    } catch (e) {
      rethrow;
    }
  }
}
