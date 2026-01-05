import 'package:equatable/equatable.dart';

sealed class DoorUnlockEvent extends Equatable {
  const DoorUnlockEvent();

  @override
  List<Object?> get props => [];
}

class DoorUnlockRequested extends DoorUnlockEvent {
  final String deviceId;
  final String doorName;

  const DoorUnlockRequested(this.deviceId, this.doorName);

  @override
  List<Object?> get props => [deviceId, doorName];
}

class DoorUnlockCancelled extends DoorUnlockEvent {
  const DoorUnlockCancelled();
}
