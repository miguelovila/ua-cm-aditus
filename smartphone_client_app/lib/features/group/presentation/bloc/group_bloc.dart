import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/usecases/get_groups_usecase.dart';
import 'group_event.dart';
import 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GetGroupsUseCase _getGroupsUseCase;

  GroupBloc({GroupRepository? repository})
    : _getGroupsUseCase = GetGroupsUseCase(repository ?? GroupRepositoryImpl()),
      super(const GroupInitial()) {
    on<GroupLoadRequested>(_onLoadRequested);
    on<GroupRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    GroupLoadRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(const GroupLoading());
    try {
      final groups = await _getGroupsUseCase();
      emit(GroupLoaded(groups));
    } catch (e) {
      emit(GroupError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    GroupRefreshRequested event,
    Emitter<GroupState> emit,
  ) async {
    try {
      final groups = await _getGroupsUseCase();
      emit(GroupLoaded(groups));
      event.completer?.complete();
    } catch (e) {
      emit(GroupError(e.toString()));
      event.completer?.completeError(e);
    }
  }
}
