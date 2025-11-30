import 'package:equatable/equatable.dart';
import '../../data/models/device.dart';

sealed class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {
  const DeviceInitial();
}

class DeviceLoading extends DeviceState {
  const DeviceLoading();
}

class DeviceLoaded extends DeviceState {
  final List<Device> devices;
  final int? currentDeviceId;

  const DeviceLoaded(this.devices, {this.currentDeviceId});

  @override
  List<Object?> get props => [devices, currentDeviceId];
}

class DeviceError extends DeviceState {
  final String message;

  const DeviceError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceRegistering extends DeviceState {
  const DeviceRegistering();
}

class DeviceRegistered extends DeviceState {
  const DeviceRegistered();
}

class DeviceRegistrationError extends DeviceState {
  final String message;

  const DeviceRegistrationError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceDeleting extends DeviceState {
  final int deviceId;

  const DeviceDeleting(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class DeviceDeleted extends DeviceState {
  const DeviceDeleted();
}
