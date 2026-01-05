import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/security/crypto_service.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/core/services/ble_service.dart';
import 'door_unlock_event.dart';
import 'door_unlock_state.dart';

class DoorUnlockBloc extends Bloc<DoorUnlockEvent, DoorUnlockState> {
  final BleService _bleService;
  final CryptoService _cryptoService;
  final SecureStorageService _storage;

  DoorUnlockBloc({
    BleService? bleService,
    CryptoService? cryptoService,
    SecureStorageService? storage,
  }) : _bleService = bleService ?? BleService(),
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
      _log('Starting unlock request for device: ${event.deviceId}');

      emit(const DoorUnlockInProgress('Preparing...'));
      final userJson = await _storage.getUserData();
      final userId = userJson?['id']?.toString();
      final deviceId = await _storage.getDeviceId();
      _log('User ID: $userId, Device ID: $deviceId');

      if (userId == null || deviceId == null) {
        _log('Authentication failed: missing credentials');
        emit(
          const DoorUnlockFailure('User not authenticated', canRetry: false),
        );
        return;
      }

      emit(const DoorUnlockInProgress('Connecting to door...'));
      _log('Connecting to BLE device...');
      await _bleService.connectToDevice(event.deviceId);
      _log('Connected successfully');

      emit(const DoorUnlockInProgress('Discovering services...'));
      _log('Discovering services...');
      await _bleService.discoverServices(event.deviceId);
      _log('Services discovered');

      const challengeUuid = '6a3d9e2c-2a9a-4c1b-8f0a-7b8b5a3d0b1a';
      const statusUuid = '8f0a7b8b-5a3d-4c1b-8f0a-6f3d9e2c2a9a';

      _log('Subscribing to challenge characteristic...');
      final challengeStream = await _bleService.listenToCharacteristic(
        challengeUuid,
      );
      _log('Challenge stream obtained');

      _log('Subscribing to status characteristic...');
      final statusStream = await _bleService.listenToCharacteristic(statusUuid);
      _log('Status stream obtained');

      // Small delay to ensure subscriptions are fully active
      _log('Waiting 100ms for subscriptions to stabilize...');
      await Future.delayed(const Duration(milliseconds: 100));

      emit(const DoorUnlockInProgress('Authenticating...'));
      const idUuid = '5f2e6f9a-6f3d-4a1b-8f0a-7b8b5a3d0b1a';
      final idPayload = json.encode({'user_id': userId, 'device_id': deviceId});
      _log('Writing ID payload: $idPayload');
      await _bleService.writeToCharacteristic(idUuid, idPayload);
      _log('ID payload written successfully');

      _log('Waiting for challenge from ESP32...');
      final challenge = await challengeStream.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('TIMEOUT: Challenge not received within 30 seconds');
          throw TimeoutException('Challenge not received');
        },
      );
      _log('Challenge received: $challenge');

      emit(const DoorUnlockInProgress('Signing challenge...'));
      _log('Signing challenge...');
      final signature = await _cryptoService.signData(challenge);
      _log('Challenge signed, signature length: ${signature.length}');

      const signatureUuid = '7b8b5a3d-0b1a-4c1b-8f0a-6f3d9e2c2a9a';
      _log('Writing signature to characteristic...');
      await _bleService.writeToCharacteristic(
        signatureUuid,
        signature,
        allowLongWrite: true,
      );
      _log('Signature written successfully');

      emit(const DoorUnlockInProgress('Unlocking...'));
      _log('Waiting for status response...');
      final status = await statusStream.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('TIMEOUT: Status not received within 30 seconds');
          throw TimeoutException('Status not received');
        },
      );
      _log('Status received: $status');

      if (status == 'AUTHORIZED') {
        _log('Access authorized, door unlocked!');
        emit(DoorUnlockSuccess(event.doorName));
      } else {
        _log('Access denied: $status');
        final errorMessage = _parseErrorStatus(status);
        emit(DoorUnlockFailure(errorMessage, canRetry: _canRetry(status)));
      }

      _log('Disconnecting from device...');
      await _bleService.disconnectFromDevice();
      _log('Disconnected');
    } on TimeoutException catch (e) {
      _log('TimeoutException: ${e.message}');
      emit(DoorUnlockFailure('Operation timed out: ${e.message}'));
      await _bleService.disconnectFromDevice();
    } catch (e, stackTrace) {
      _log('Exception during unlock: $e');
      _log('Stack trace: $stackTrace');
      emit(DoorUnlockFailure(e.toString()));
      await _bleService.disconnectFromDevice();
    }
  }

  String _parseErrorStatus(String status) {
    // Map ESP32 status codes to user-friendly messages
    if (status.startsWith('DENIED_')) {
      final reason = status.substring(7);
      return switch (reason) {
        'no_permission' => 'You do not have permission to access this door',
        'user_not_found' => 'User account not found',
        'door_not_found' => 'Door configuration not found',
        'door_inactive' => 'This door is currently inactive',
        'KEY_FETCH_FAILED' => 'Failed to retrieve security credentials',
        'KEY_UNAVAILABLE' => 'Security credentials unavailable',
        'INVALID_SIGNATURE' => 'Authentication failed: Invalid signature',
        'INVALID_STATE' => 'Door is in invalid state',
        'TIMEOUT' => 'Request timed out',
        'BACKEND_ERROR' =>
          'Backend service is currently unavailable. Please try again.',
        'NETWORK_ERROR' =>
          'Network connection error. Please check your connection.',
        _ => 'Access denied: $reason',
      };
    }
    return 'Unknown status: $status';
  }

  bool _canRetry(String status) {
    return !status.contains('no_permission') &&
        !status.contains('user_not_found') &&
        !status.contains('INVALID_SIGNATURE');
  }

  Future<void> _onUnlockCancelled(
    DoorUnlockCancelled event,
    Emitter<DoorUnlockState> emit,
  ) async {
    await _bleService.disconnectFromDevice();
    emit(const DoorUnlockInitial());
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[DoorUnlockBloc] $message');
    }
  }

  @override
  Future<void> close() {
    _bleService.disconnectFromDevice();
    return super.close();
  }
}
