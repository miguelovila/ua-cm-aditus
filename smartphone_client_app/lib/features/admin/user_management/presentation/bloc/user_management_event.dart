import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../data/models/user_create_request.dart';
import '../../data/models/user_update_request.dart';

sealed class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Load all users
class UserManagementLoadAllRequested extends UserManagementEvent {
  const UserManagementLoadAllRequested();
}

/// Refresh users list (pull-to-refresh)
class UserManagementRefreshRequested extends UserManagementEvent {
  final Completer<void>? completer;

  const UserManagementRefreshRequested([this.completer]);

  @override
  List<Object?> get props => [completer];
}

/// Load single user by ID
class UserManagementLoadByIdRequested extends UserManagementEvent {
  final int userId;

  const UserManagementLoadByIdRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Create new user
class UserManagementCreateRequested extends UserManagementEvent {
  final UserCreateRequest request;

  const UserManagementCreateRequested(this.request);

  @override
  List<Object> get props => [request];
}

/// Update existing user
class UserManagementUpdateRequested extends UserManagementEvent {
  final int userId;
  final UserUpdateRequest request;

  const UserManagementUpdateRequested(this.userId, this.request);

  @override
  List<Object> get props => [userId, request];
}

/// Delete user
class UserManagementDeleteRequested extends UserManagementEvent {
  final int userId;

  const UserManagementDeleteRequested(this.userId);

  @override
  List<Object> get props => [userId];
}
