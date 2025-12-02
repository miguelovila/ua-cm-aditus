import 'package:equatable/equatable.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';

sealed class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

/// Loading state (for initial load)
class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

/// Users loaded successfully
class UserManagementLoaded extends UserManagementState {
  final List<User> users;

  const UserManagementLoaded(this.users);

  @override
  List<Object> get props => [users];
}

/// Single user loaded (detail view)
class UserManagementDetailLoaded extends UserManagementState {
  final User user;

  const UserManagementDetailLoaded(this.user);

  @override
  List<Object> get props => [user];
}

/// Loading details for a single user
class UserManagementDetailLoading extends UserManagementState {
  const UserManagementDetailLoading();
}

/// Operation in progress (create/update/delete)
class UserManagementOperationInProgress extends UserManagementState {
  final String operation; // "creating", "updating", "deleting"

  const UserManagementOperationInProgress(this.operation);

  @override
  List<Object> get props => [operation];
}

/// Operation succeeded
class UserManagementOperationSuccess extends UserManagementState {
  final String message;
  final List<User>? users; // Updated list if available

  const UserManagementOperationSuccess(this.message, {this.users});

  @override
  List<Object?> get props => [message, users];
}

/// Error state
class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object> get props => [message];
}
