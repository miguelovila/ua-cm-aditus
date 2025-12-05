import 'dart:async';
import 'door_discovery_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'door_discovery_state.dart';
import 'package:smartphone_client_app/core/services/services.dart';

class DoorDiscoveryBloc extends Bloc<DoorDiscoveryEvent, DoorDiscoveryState> {
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

    // Listen to BLE service streams
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
      emit(DoorDiscoveryError(e.toString()));
    }
  }

  Future<void> _onStopScanRequested(
    StopScanRequested event,
    Emitter<DoorDiscoveryState> emit,
  ) async {
    await _bleService.stopScan();

    // Keep the last discovered doors when stopping
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
    // Auto-stop handling if scan timeout completes
    if (!event.isScanning && state is DoorDiscoveryScanning) {
      final currentDoors = (state as DoorDiscoveryScanning).discoveredDoors;
      emit(DoorDiscoveryCompleted(currentDoors));
    }
  }

  @override
  Future<void> close() {
    _scanResultsSubscription?.cancel();
    _scanStateSubscription?.cancel();
    _bleService.stopScan();
    return super.close();
  }
}
