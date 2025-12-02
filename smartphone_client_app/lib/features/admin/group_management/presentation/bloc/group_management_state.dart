import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';

sealed class GroupManagementState extends Equatable {
  const GroupManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GroupManagementInitial extends GroupManagementState {
  const GroupManagementInitial();
}

/// Loading state (for initial load)
class GroupManagementLoading extends GroupManagementState {
  const GroupManagementLoading();
}

/// Groups loaded successfully
class GroupManagementLoaded extends GroupManagementState {
  final List<Group> groups;

  const GroupManagementLoaded(this.groups);

  @override
  List<Object> get props => [groups];
}

/// Single group loaded (detail view)
class GroupManagementDetailLoaded extends GroupManagementState {
  final Group group;

  const GroupManagementDetailLoaded(this.group);

  @override
  List<Object> get props => [group];
}

/// Loading details for a single group
class GroupManagementDetailLoading extends GroupManagementState {
  const GroupManagementDetailLoading();
}

/// Operation in progress (create/update/delete)
class GroupManagementOperationInProgress extends GroupManagementState {
  final String operation; // "creating", "updating", "deleting"

  const GroupManagementOperationInProgress(this.operation);

  @override
  List<Object> get props => [operation];
}

/// Operation succeeded
class GroupManagementOperationSuccess extends GroupManagementState {
  final String message;
  final List<Group>? groups; // Updated list if available

  const GroupManagementOperationSuccess(this.message, {this.groups});

  @override
  List<Object?> get props => [message, groups];
}

/// Error state
class GroupManagementError extends GroupManagementState {
  final String message;

  const GroupManagementError(this.message);

  @override
  List<Object> get props => [message];
}
