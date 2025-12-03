import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';

sealed class DoorManagementState extends Equatable {
  const DoorManagementState();

  @override
  List<Object?> get props => [];
}

class DoorManagementInitial extends DoorManagementState {
  const DoorManagementInitial();
}

class DoorManagementLoading extends DoorManagementState {
  const DoorManagementLoading();
}

class DoorManagementLoaded extends DoorManagementState {
  final List<Door> doors;

  const DoorManagementLoaded(this.doors);

  @override
  List<Object> get props => [doors];
}

class DoorManagementDetailLoaded extends DoorManagementState {
  final Door door;

  const DoorManagementDetailLoaded(this.door);

  @override
  List<Object> get props => [door];
}

class DoorManagementDetailLoading extends DoorManagementState {
  const DoorManagementDetailLoading();
}

class DoorManagementOperationInProgress extends DoorManagementState {
  final String operation; // "creating", "updating", "deleting"

  const DoorManagementOperationInProgress(this.operation);

  @override
  List<Object> get props => [operation];
}

class DoorManagementOperationSuccess extends DoorManagementState {
  final String message;
  final List<Door>? doors; // Updated list if available

  const DoorManagementOperationSuccess(this.message, {this.doors});

  @override
  List<Object?> get props => [message, doors];
}

class DoorManagementError extends DoorManagementState {
  final String message;

  const DoorManagementError(this.message);

  @override
  List<Object> get props => [message];
}
