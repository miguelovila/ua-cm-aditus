import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartwatch_client_app/bloc/door_unlock_event.dart';
import 'package:smartwatch_client_app/bloc/door_unlock_state.dart';
import 'package:smartwatch_client_app/services/ble_service.dart';
import 'package:smartwatch_client_app/services/crypto_service.dart';
import 'package:smartwatch_client_app/services/secure_storage_service.dart';

class DoorUnlockBloc extends Bloc<DoorUnlockEvent, DoorUnlockState> {
  final BleService _bleService;
  final CryptoService _cryptoService;
  final SecureStorageService _storage;

  DoorUnlockBloc({
    BleService? bleService,
    CryptoService? cryptoService,
    SecureStorageService? storage,
  })  : _bleService = bleService ?? BleService(),
        _cryptoService = cryptoService ?? CryptoService(),
        _storage = storage ?? SecureStorageService(),
        super(const DoorUnlockInitial()) {
    on<DoorUnlockRequested>(_onUnlockRequested);
    on<DoorUnlockCancelled>(_onUnlockCancelled);
  }

  Future<void> _onUnlockRequested(
    DoorUnlockRequested event,
    Emitter<DoorUnlockState> emit,
  ) async {
    try {
      emit(const DoorUnlockInProgress('Preparing...'));

      final userId = await _storage.getUserId();
      final deviceId = await _storage.getDeviceId();

      if (userId == null || deviceId == null) {
        emit(const DoorUnlockFailure('Device not registered', canRetry: false));
        return;
      }

      emit(const DoorUnlockInProgress('Connecting...'));
      await _bleService.connectToDevice(event.deviceId);

      emit(const DoorUnlockInProgress('Discovering...'));
      await _bleService.discoverServices(event.deviceId);

      final challengeStream = await _bleService.listenToCharacteristic(
        BleService.challengeUuid,
      );

      final statusStream = await _bleService.listenToCharacteristic(
        BleService.statusUuid,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      emit(const DoorUnlockInProgress('Authenticating...'));
      final idPayload = json.encode({
        'user_id': userId,
        'device_id': deviceId,
      });
      await _bleService.writeToCharacteristic(
        BleService.idUuid,
        idPayload,
      );

      final challenge = await challengeStream.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Challenge timeout');
        },
      );

      emit(const DoorUnlockInProgress('Signing...'));
      final signature = await _cryptoService.signData(challenge);

      await _bleService.writeToCharacteristic(
        BleService.signatureUuid,
        signature,
        allowLongWrite: true,
      );

      emit(const DoorUnlockInProgress('Unlocking...'));
      final status = await statusStream.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Status timeout');
        },
      );

      if (status == 'AUTHORIZED') {
        emit(DoorUnlockSuccess(event.doorName));
      } else {
        final errorMessage = _parseErrorStatus(status);
        emit(DoorUnlockFailure(errorMessage, canRetry: _canRetry(status)));
      }

      await _bleService.disconnectFromDevice();
    } on TimeoutException catch (e) {
      emit(DoorUnlockFailure('Timeout: ${e.message ?? "operation timed out"}'));
      await _bleService.disconnectFromDevice();
    } catch (e) {
      emit(DoorUnlockFailure(_simplifyError(e.toString())));
      await _bleService.disconnectFromDevice();
    }
  }

  Future<void> _onUnlockCancelled(
    DoorUnlockCancelled event,
    Emitter<DoorUnlockState> emit,
  ) async {
    await _bleService.disconnectFromDevice();
    emit(const DoorUnlockInitial());
  }

  String _parseErrorStatus(String status) {
    if (status.startsWith('DENIED_')) {
      final reason = status.substring(7);
      return switch (reason) {
        'no_permission' => 'No permission',
        'user_not_found' => 'User not found',
        'door_not_found' => 'Door not found',
        'door_inactive' => 'Door inactive',
        'KEY_FETCH_FAILED' => 'Key fetch failed',
        'KEY_UNAVAILABLE' => 'Key unavailable',
        'INVALID_SIGNATURE' => 'Invalid signature',
        'INVALID_STATE' => 'Invalid state',
        'TIMEOUT' => 'Timeout',
        'BACKEND_ERROR' => 'Backend error',
        'NETWORK_ERROR' => 'Network error',
        _ => 'Denied: $reason',
      };
    }
    return 'Unknown: $status';
  }

  bool _canRetry(String status) {
    return !status.contains('no_permission') &&
        !status.contains('user_not_found') &&
        !status.contains('INVALID_SIGNATURE');
  }

  String _simplifyError(String error) {
    final lowerError = error.toLowerCase();
    if (lowerError.contains('bluetooth') || lowerError.contains('ble')) {
      return 'Bluetooth error';
    } else if (lowerError.contains('permission')) {
      return 'Permission denied';
    } else if (lowerError.contains('connection') || lowerError.contains('connect')) {
      return 'Connection failed';
    } else if (lowerError.contains('timeout')) {
      return 'Timeout';
    } else if (lowerError.contains('not found')) {
      return 'Not found';
    }
    return 'Error';
  }

  @override
  Future<void> close() async {
    await _bleService.disconnectFromDevice();
    return super.close();
  }
}
