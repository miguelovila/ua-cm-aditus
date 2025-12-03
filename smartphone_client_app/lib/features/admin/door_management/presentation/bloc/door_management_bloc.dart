import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/repositories/admin_door_repository_impl.dart';
import 'package:smartphone_client_app/features/admin/door_management/domain/usecases/create_door_usecase.dart';
import 'package:smartphone_client_app/features/admin/door_management/domain/usecases/delete_door_usecase.dart';
import 'package:smartphone_client_app/features/admin/door_management/domain/usecases/get_all_doors_usecase.dart';
import 'package:smartphone_client_app/features/admin/door_management/domain/usecases/get_door_by_id_usecase.dart';
import 'package:smartphone_client_app/features/admin/door_management/domain/usecases/update_door_usecase.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_event.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_state.dart';

class DoorManagementBloc
    extends Bloc<DoorManagementEvent, DoorManagementState> {
  final GetAllDoorsUseCase _getAllDoorsUseCase;
  final GetDoorByIdUseCase _getDoorByIdUseCase;
  final CreateDoorUseCase _createDoorUseCase;
  final UpdateDoorUseCase _updateDoorUseCase;
  final DeleteDoorUseCase _deleteDoorUseCase;

  DoorManagementBloc({AdminDoorRepository? repository})
      : _getAllDoorsUseCase =
            GetAllDoorsUseCase(repository ?? AdminDoorRepositoryImpl()),
        _getDoorByIdUseCase =
            GetDoorByIdUseCase(repository ?? AdminDoorRepositoryImpl()),
        _createDoorUseCase =
            CreateDoorUseCase(repository ?? AdminDoorRepositoryImpl()),
        _updateDoorUseCase =
            UpdateDoorUseCase(repository ?? AdminDoorRepositoryImpl()),
        _deleteDoorUseCase =
            DeleteDoorUseCase(repository ?? AdminDoorRepositoryImpl()),
        super(const DoorManagementInitial()) {
    on<DoorManagementLoadAllRequested>(_onLoadAllRequested);
    on<DoorManagementRefreshRequested>(_onRefreshRequested);
    on<DoorManagementLoadByIdRequested>(_onLoadByIdRequested);
    on<DoorManagementCreateRequested>(_onCreateRequested);
    on<DoorManagementUpdateRequested>(_onUpdateRequested);
    on<DoorManagementDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadAllRequested(
    DoorManagementLoadAllRequested event,
    Emitter<DoorManagementState> emit,
  ) async {
    emit(const DoorManagementLoading());
    try {
      final doors = await _getAllDoorsUseCase();
      emit(DoorManagementLoaded(doors));
    } catch (e) {
      emit(DoorManagementError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    DoorManagementRefreshRequested event,
    Emitter<DoorManagementState> emit,
  ) async {
    try {
      final doors = await _getAllDoorsUseCase();
      emit(DoorManagementLoaded(doors));
      event.completer?.complete();
    } catch (e) {
      emit(DoorManagementError(e.toString()));
      event.completer?.completeError(e);
    }
  }

  Future<void> _onLoadByIdRequested(
    DoorManagementLoadByIdRequested event,
    Emitter<DoorManagementState> emit,
  ) async {
    emit(const DoorManagementDetailLoading());
    try {
      final door = await _getDoorByIdUseCase(event.doorId);
      emit(DoorManagementDetailLoaded(door));
    } catch (e) {
      emit(DoorManagementError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    DoorManagementCreateRequested event,
    Emitter<DoorManagementState> emit,
  ) async {
    emit(const DoorManagementOperationInProgress('creating'));
    try {
      await _createDoorUseCase(event.request);
      final doors = await _getAllDoorsUseCase();
      emit(
        DoorManagementOperationSuccess(
          'Door created successfully',
          doors: doors,
        ),
      );
    } catch (e) {
      emit(DoorManagementError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    DoorManagementUpdateRequested event,
    Emitter<DoorManagementState> emit,
  ) async {
    emit(const DoorManagementOperationInProgress('updating'));
    try {
      await _updateDoorUseCase(event.doorId, event.request);
      final doors = await _getAllDoorsUseCase();
      emit(
        DoorManagementOperationSuccess(
          'Door updated successfully',
          doors: doors,
        ),
      );
    } catch (e) {
      emit(DoorManagementError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    DoorManagementDeleteRequested event,
    Emitter<DoorManagementState> emit,
  ) async {
    emit(const DoorManagementOperationInProgress('deleting'));
    try {
      await _deleteDoorUseCase(event.doorId);
      final doors = await _getAllDoorsUseCase();
      emit(
        DoorManagementOperationSuccess(
          'Door deleted successfully',
          doors: doors,
        ),
      );
    } catch (e) {
      emit(DoorManagementError(e.toString()));
    }
  }
}
