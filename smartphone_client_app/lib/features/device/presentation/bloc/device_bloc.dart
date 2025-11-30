import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/usecases/delete_device_usecase.dart';
import '../../domain/usecases/get_devices_usecase.dart';
import '../../domain/usecases/register_device_usecase.dart';
import 'device_event.dart';
import 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final GetDevicesUseCase _getDevicesUseCase;
  final RegisterDeviceUseCase _registerDeviceUseCase;
  final DeleteDeviceUseCase _deleteDeviceUseCase;
  final SecureStorageService _storageService;

  DeviceBloc({
    DeviceRepository? repository,
    SecureStorageService? storageService,
  }) : _storageService = storageService ?? SecureStorageService(),
       _getDevicesUseCase = GetDevicesUseCase(
         repository ?? DeviceRepositoryImpl(),
       ),
       _registerDeviceUseCase = RegisterDeviceUseCase(
         repository ?? DeviceRepositoryImpl(),
       ),
       _deleteDeviceUseCase = DeleteDeviceUseCase(
         repository ?? DeviceRepositoryImpl(),
       ),
       super(const DeviceInitial()) {
    on<DeviceLoadRequested>(_onLoadRequested);
    on<DeviceRefreshRequested>(_onRefreshRequested);
    on<DeviceRegisterRequested>(_onRegisterRequested);
    on<DeviceDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    DeviceLoadRequested event,
    Emitter<DeviceState> emit,
  ) async {
    emit(const DeviceLoading());
    try {
      final devices = await _getDevicesUseCase();
      final currentDeviceIdStr = await _storageService.getDeviceId();
      final currentDeviceId = currentDeviceIdStr != null
          ? int.tryParse(currentDeviceIdStr)
          : null;

      emit(DeviceLoaded(devices, currentDeviceId: currentDeviceId));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    DeviceRefreshRequested event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      final devices = await _getDevicesUseCase();
      final currentDeviceIdStr = await _storageService.getDeviceId();
      final currentDeviceId = currentDeviceIdStr != null
          ? int.tryParse(currentDeviceIdStr)
          : null;

      emit(DeviceLoaded(devices, currentDeviceId: currentDeviceId));
      event.completer?.complete();
    } catch (e) {
      emit(DeviceError(e.toString()));
      event.completer?.completeError(e);
    }
  }

  Future<void> _onRegisterRequested(
    DeviceRegisterRequested event,
    Emitter<DeviceState> emit,
  ) async {
    emit(const DeviceRegistering());
    try {
      await _registerDeviceUseCase(event.deviceName);
      emit(const DeviceRegistered());
    } catch (e) {
      emit(DeviceRegistrationError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    DeviceDeleteRequested event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceDeleting(event.deviceId));
    try {
      await _deleteDeviceUseCase(event.deviceId);

      // Reload devices list
      final devices = await _getDevicesUseCase();
      final currentDeviceIdStr = await _storageService.getDeviceId();
      final currentDeviceId = currentDeviceIdStr != null
          ? int.tryParse(currentDeviceIdStr)
          : null;

      emit(const DeviceDeleted());
      emit(DeviceLoaded(devices, currentDeviceId: currentDeviceId));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }
}
