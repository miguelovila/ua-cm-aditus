import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/admin_group_repository.dart';
import '../../data/repositories/admin_group_repository_impl.dart';
import '../../domain/usecases/add_members_usecase.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/delete_group_usecase.dart';
import '../../domain/usecases/get_all_groups_usecase.dart';
import '../../domain/usecases/get_group_by_id_usecase.dart';
import '../../domain/usecases/remove_member_usecase.dart';
import '../../domain/usecases/update_group_usecase.dart';
import 'group_management_event.dart';
import 'group_management_state.dart';

class GroupManagementBloc
    extends Bloc<GroupManagementEvent, GroupManagementState> {
  final GetAllGroupsUseCase _getAllGroupsUseCase;
  final GetGroupByIdUseCase _getGroupByIdUseCase;
  final CreateGroupUseCase _createGroupUseCase;
  final UpdateGroupUseCase _updateGroupUseCase;
  final DeleteGroupUseCase _deleteGroupUseCase;
  final AddMembersUseCase _addMembersUseCase;
  final RemoveMemberUseCase _removeMemberUseCase;

  GroupManagementBloc({AdminGroupRepository? repository})
      : _getAllGroupsUseCase =
            GetAllGroupsUseCase(repository ?? AdminGroupRepositoryImpl()),
        _getGroupByIdUseCase =
            GetGroupByIdUseCase(repository ?? AdminGroupRepositoryImpl()),
        _createGroupUseCase =
            CreateGroupUseCase(repository ?? AdminGroupRepositoryImpl()),
        _updateGroupUseCase =
            UpdateGroupUseCase(repository ?? AdminGroupRepositoryImpl()),
        _deleteGroupUseCase =
            DeleteGroupUseCase(repository ?? AdminGroupRepositoryImpl()),
        _addMembersUseCase =
            AddMembersUseCase(repository ?? AdminGroupRepositoryImpl()),
        _removeMemberUseCase =
            RemoveMemberUseCase(repository ?? AdminGroupRepositoryImpl()),
        super(const GroupManagementInitial()) {
    on<GroupManagementLoadAllRequested>(_onLoadAllRequested);
    on<GroupManagementRefreshRequested>(_onRefreshRequested);
    on<GroupManagementLoadByIdRequested>(_onLoadByIdRequested);
    on<GroupManagementCreateRequested>(_onCreateRequested);
    on<GroupManagementUpdateRequested>(_onUpdateRequested);
    on<GroupManagementDeleteRequested>(_onDeleteRequested);
    on<GroupManagementAddMembersRequested>(_onAddMembersRequested);
    on<GroupManagementRemoveMemberRequested>(_onRemoveMemberRequested);
  }

  Future<void> _onLoadAllRequested(
    GroupManagementLoadAllRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementLoading());
    try {
      final groups = await _getAllGroupsUseCase();
      emit(GroupManagementLoaded(groups));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    GroupManagementRefreshRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    try {
      final groups = await _getAllGroupsUseCase();
      emit(GroupManagementLoaded(groups));
      event.completer?.complete();
    } catch (e) {
      emit(GroupManagementError(e.toString()));
      event.completer?.completeError(e);
    }
  }

  Future<void> _onLoadByIdRequested(
    GroupManagementLoadByIdRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementDetailLoading());
    try {
      final group = await _getGroupByIdUseCase(event.groupId);
      emit(GroupManagementDetailLoaded(group));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    GroupManagementCreateRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementOperationInProgress('creating'));
    try {
      await _createGroupUseCase(event.request);
      final groups = await _getAllGroupsUseCase();
      emit(GroupManagementOperationSuccess(
        'Group created successfully',
        groups: groups,
      ));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    GroupManagementUpdateRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementOperationInProgress('updating'));
    try {
      await _updateGroupUseCase(event.groupId, event.request);
      final groups = await _getAllGroupsUseCase();
      emit(GroupManagementOperationSuccess(
        'Group updated successfully',
        groups: groups,
      ));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    GroupManagementDeleteRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementOperationInProgress('deleting'));
    try {
      await _deleteGroupUseCase(event.groupId);
      final groups = await _getAllGroupsUseCase();
      emit(GroupManagementOperationSuccess(
        'Group deleted successfully',
        groups: groups,
      ));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }

  Future<void> _onAddMembersRequested(
    GroupManagementAddMembersRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementOperationInProgress('adding members'));
    try {
      await _addMembersUseCase(event.groupId, event.userIds);
      final group = await _getGroupByIdUseCase(event.groupId);
      emit(GroupManagementDetailLoaded(group));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }

  Future<void> _onRemoveMemberRequested(
    GroupManagementRemoveMemberRequested event,
    Emitter<GroupManagementState> emit,
  ) async {
    emit(const GroupManagementOperationInProgress('removing member'));
    try {
      await _removeMemberUseCase(event.groupId, event.userId);
      final group = await _getGroupByIdUseCase(event.groupId);
      emit(GroupManagementDetailLoaded(group));
    } catch (e) {
      emit(GroupManagementError(e.toString()));
    }
  }
}
