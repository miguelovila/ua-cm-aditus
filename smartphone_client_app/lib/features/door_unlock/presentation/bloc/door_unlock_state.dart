import 'package:equatable/equatable.dart';

sealed class DoorUnlockState extends Equatable {
  const DoorUnlockState();

  @override
  List<Object?> get props => [];
}

class DoorUnlockInitial extends DoorUnlockState {
  const DoorUnlockInitial();
}

class DoorUnlockInProgress extends DoorUnlockState {
  final String status; // "Connecting", "Authenticating", "Unlocking", etc.

  const DoorUnlockInProgress(this.status);

  @override
  List<Object?> get props => [status];
}

class DoorUnlockSuccess extends DoorUnlockState {
  final String doorName;

  const DoorUnlockSuccess(this.doorName);

  @override
  List<Object?> get props => [doorName];
}

class DoorUnlockFailure extends DoorUnlockState {
  final String error;
  final bool canRetry;

  const DoorUnlockFailure(this.error, {this.canRetry = true});

  @override
  List<Object?> get props => [error, canRetry];
}
