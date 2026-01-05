import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartwatch_client_app/bloc/door_discovery_event.dart';
import 'package:smartwatch_client_app/bloc/door_discovery_state.dart';
import 'package:smartwatch_client_app/services/ble_service.dart';

class DoorDiscoveryBloc
    extends Bloc<DoorDiscoveryEvent, DoorDiscoveryState> {
  final BleService _bleService;
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _scanStateSubscription;

  DoorDiscoveryBloc({BleService? bleService})
      : _bleService = bleService ?? BleService(),
        super(const DoorDiscoveryInitial()) {
    on<StartScanRequested>(_onStartScanRequested);
    on<StopScanRequested>(_onStopScanRequested);
    on<DevicesDiscovered>(_onDevicesDiscovered);
    on<ScanStateChanged>(_onScanStateChanged);

    _scanResultsSubscription = _bleService.scanResults.listen((doors) {
      add(DevicesDiscovered(doors));
    });

    _scanStateSubscription = _bleService.scanState.listen((isScanning) {
      add(ScanStateChanged(isScanning));
    });
  }

  Future<void> _onStartScanRequested(
    StartScanRequested event,
    Emitter<DoorDiscoveryState> emit,
  ) async {
    emit(const DoorDiscoveryScanning());
    try {
      await _bleService.startScan();
    } catch (e) {
      emit(DoorDiscoveryError(_simplifyError(e.toString())));
    }
  }

  Future<void> _onStopScanRequested(
    StopScanRequested event,
    Emitter<DoorDiscoveryState> emit,
  ) async {
    await _bleService.stopScan();
    if (state is DoorDiscoveryScanning) {
      final currentDoors = (state as DoorDiscoveryScanning).discoveredDoors;
      emit(DoorDiscoveryCompleted(currentDoors));
    } else {
      emit(const DoorDiscoveryCompleted([]));
    }
  }

  void _onDevicesDiscovered(
    DevicesDiscovered event,
    Emitter<DoorDiscoveryState> emit,
  ) {
    if (state is DoorDiscoveryScanning) {
      emit(DoorDiscoveryScanning(discoveredDoors: event.doors));
    }
  }

  void _onScanStateChanged(
    ScanStateChanged event,
    Emitter<DoorDiscoveryState> emit,
  ) {
    if (!event.isScanning && state is DoorDiscoveryScanning) {
      final currentDoors = (state as DoorDiscoveryScanning).discoveredDoors;
      emit(DoorDiscoveryCompleted(currentDoors));
    }
  }

  String _simplifyError(String error) {
    final lowerError = error.toLowerCase();
    if (lowerError.contains('bluetooth') && lowerError.contains('off')) {
      return 'Bluetooth is off';
    } else if (lowerError.contains('bluetooth') || lowerError.contains('not supported')) {
      return 'Bluetooth error';
    } else if (lowerError.contains('permission')) {
      return 'Permission denied';
    }
    return 'Scan failed';
  }

  @override
  Future<void> close() async {
    await _scanResultsSubscription?.cancel();
    await _scanStateSubscription?.cancel();
    await _bleService.stopScan();
    return super.close();
  }
}
