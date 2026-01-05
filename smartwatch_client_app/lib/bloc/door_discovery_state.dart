import 'package:equatable/equatable.dart';
import 'package:smartwatch_client_app/services/ble_service.dart';

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

  bool get hasDevices => discoveredDoors.isNotEmpty;

  DiscoveredDoor? get nearestDoor {
    if (discoveredDoors.isEmpty) return null;

    final sorted = List<DiscoveredDoor>.from(discoveredDoors)
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return sorted.first;
  }

  @override
  List<Object?> get props => [discoveredDoors];
}

class DoorDiscoveryCompleted extends DoorDiscoveryState {
  final List<DiscoveredDoor> discoveredDoors;

  const DoorDiscoveryCompleted(this.discoveredDoors);

  bool get hasDevices => discoveredDoors.isNotEmpty;

  DiscoveredDoor? get nearestDoor {
    if (discoveredDoors.isEmpty) return null;

    final sorted = List<DiscoveredDoor>.from(discoveredDoors)
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return sorted.first;
  }

  @override
  List<Object?> get props => [discoveredDoors];
}

class DoorDiscoveryError extends DoorDiscoveryState {
  final String message;

  const DoorDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
