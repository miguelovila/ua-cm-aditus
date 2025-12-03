import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_create_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_update_request.dart';

sealed class DoorManagementEvent extends Equatable {
  const DoorManagementEvent();

  @override
  List<Object?> get props => [];
}

// Load all doors
class DoorManagementLoadAllRequested extends DoorManagementEvent {
  const DoorManagementLoadAllRequested();
}

// Refresh doors list (pull-to-refresh)
class DoorManagementRefreshRequested extends DoorManagementEvent {
  final Completer<void>? completer;

  const DoorManagementRefreshRequested([this.completer]);

  @override
  List<Object?> get props => [completer];
}

// Load single door by ID
class DoorManagementLoadByIdRequested extends DoorManagementEvent {
  final int doorId;

  const DoorManagementLoadByIdRequested(this.doorId);

  @override
  List<Object> get props => [doorId];
}

// Create new door
class DoorManagementCreateRequested extends DoorManagementEvent {
  final DoorCreateRequest request;

  const DoorManagementCreateRequested(this.request);

  @override
  List<Object> get props => [request];
}

// Update existing door
class DoorManagementUpdateRequested extends DoorManagementEvent {
  final int doorId;
  final DoorUpdateRequest request;

  const DoorManagementUpdateRequested(this.doorId, this.request);

  @override
  List<Object> get props => [doorId, request];
}

// Delete door
class DoorManagementDeleteRequested extends DoorManagementEvent {
  final int doorId;

  const DoorManagementDeleteRequested(this.doorId);

  @override
  List<Object> get props => [doorId];
}
