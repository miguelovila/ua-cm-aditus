import 'dart:async';
import 'package:equatable/equatable.dart';

sealed class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object?> get props => [];
}

class DeviceLoadRequested extends DeviceEvent {
  const DeviceLoadRequested();
}

class DeviceRefreshRequested extends DeviceEvent {
  final Completer<void>? completer;

  const DeviceRefreshRequested([this.completer]);

  @override
  List<Object?> get props => [completer];
}

class DeviceRegisterRequested extends DeviceEvent {
  final String deviceName;

  const DeviceRegisterRequested(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

class DeviceDeleteRequested extends DeviceEvent {
  final int deviceId;

  const DeviceDeleteRequested(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}
