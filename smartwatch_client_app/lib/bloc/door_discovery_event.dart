import 'package:equatable/equatable.dart';
import 'package:smartwatch_client_app/services/ble_service.dart';

sealed class DoorDiscoveryEvent extends Equatable {
  const DoorDiscoveryEvent();

  @override
  List<Object?> get props => [];
}

class StartScanRequested extends DoorDiscoveryEvent {
  const StartScanRequested();
}

class StopScanRequested extends DoorDiscoveryEvent {
  const StopScanRequested();
}

class DevicesDiscovered extends DoorDiscoveryEvent {
  final List<DiscoveredDoor> doors;

  const DevicesDiscovered(this.doors);

  @override
  List<Object?> get props => [doors];
}

class ScanStateChanged extends DoorDiscoveryEvent {
  final bool isScanning;

  const ScanStateChanged(this.isScanning);

  @override
  List<Object?> get props => [isScanning];
}
