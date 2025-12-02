import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../../data/repositories/admin_user_repository_impl.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_user_by_id_usecase.dart';
import '../../domain/usecases/update_user_usecase.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final GetAllUsersUseCase _getAllUsersUseCase;
  final GetUserByIdUseCase _getUserByIdUseCase;
  final CreateUserUseCase _createUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final DeleteUserUseCase _deleteUserUseCase;

  UserManagementBloc({AdminUserRepository? repository})
      : _getAllUsersUseCase =
            GetAllUsersUseCase(repository ?? AdminUserRepositoryImpl()),
        _getUserByIdUseCase =
            GetUserByIdUseCase(repository ?? AdminUserRepositoryImpl()),
        _createUserUseCase =
            CreateUserUseCase(repository ?? AdminUserRepositoryImpl()),
        _updateUserUseCase =
            UpdateUserUseCase(repository ?? AdminUserRepositoryImpl()),
        _deleteUserUseCase =
            DeleteUserUseCase(repository ?? AdminUserRepositoryImpl()),
        super(const UserManagementInitial()) {
    on<UserManagementLoadAllRequested>(_onLoadAllRequested);
    on<UserManagementRefreshRequested>(_onRefreshRequested);
    on<UserManagementLoadByIdRequested>(_onLoadByIdRequested);
    on<UserManagementCreateRequested>(_onCreateRequested);
    on<UserManagementUpdateRequested>(_onUpdateRequested);
    on<UserManagementDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadAllRequested(
    UserManagementLoadAllRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementLoading());
    try {
      final users = await _getAllUsersUseCase();
      emit(UserManagementLoaded(users));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    UserManagementRefreshRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final users = await _getAllUsersUseCase();
      emit(UserManagementLoaded(users));
      event.completer?.complete();
    } catch (e) {
      emit(UserManagementError(e.toString()));
      event.completer?.completeError(e);
    }
  }

  Future<void> _onLoadByIdRequested(
    UserManagementLoadByIdRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementDetailLoading());
    try {
      final user = await _getUserByIdUseCase(event.userId);
      emit(UserManagementDetailLoaded(user));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    UserManagementCreateRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementOperationInProgress('creating'));
    try {
      await _createUserUseCase(event.request);
      final users = await _getAllUsersUseCase();
      emit(UserManagementOperationSuccess(
        'User created successfully',
        users: users,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    UserManagementUpdateRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementOperationInProgress('updating'));
    try {
      await _updateUserUseCase(event.userId, event.request);
      final users = await _getAllUsersUseCase();
      emit(UserManagementOperationSuccess(
        'User updated successfully',
        users: users,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    UserManagementDeleteRequested event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(const UserManagementOperationInProgress('deleting'));
    try {
      await _deleteUserUseCase(event.userId);
      final users = await _getAllUsersUseCase();
      emit(UserManagementOperationSuccess(
        'User deleted successfully',
        users: users,
      ));
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }
}
