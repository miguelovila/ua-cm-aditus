import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/core/services/services.dart';

sealed class DoorDiscoveryState extends Equatable {
  const DoorDiscoveryState();

  @override
  List<Object?> get props => [];
}

class DoorDiscoveryInitial extends DoorDiscoveryState {
  const DoorDiscoveryInitial();
}

class DoorDiscoveryScanning extends DoorDiscoveryState {
  final List<DiscoveredDoor> discoveredDoors;

  const DoorDiscoveryScanning({this.discoveredDoors = const []});

  @override
  List<Object?> get props => [discoveredDoors];

  bool get hasDevices => discoveredDoors.isNotEmpty;
}

class DoorDiscoveryCompleted extends DoorDiscoveryState {
  final List<DiscoveredDoor> discoveredDoors;

  const DoorDiscoveryCompleted(this.discoveredDoors);

  @override
  List<Object?> get props => [discoveredDoors];

  bool get hasDevices => discoveredDoors.isNotEmpty;
}

class DoorDiscoveryError extends DoorDiscoveryState {
  final String message;

  const DoorDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
