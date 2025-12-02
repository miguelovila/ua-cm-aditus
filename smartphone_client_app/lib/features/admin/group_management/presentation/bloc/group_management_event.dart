import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../data/models/group_create_request.dart';
import '../../data/models/group_update_request.dart';

sealed class GroupManagementEvent extends Equatable {
  const GroupManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Load all groups
class GroupManagementLoadAllRequested extends GroupManagementEvent {
  const GroupManagementLoadAllRequested();
}

/// Refresh groups list (pull-to-refresh)
class GroupManagementRefreshRequested extends GroupManagementEvent {
  final Completer<void>? completer;

  const GroupManagementRefreshRequested([this.completer]);

  @override
  List<Object?> get props => [completer];
}

/// Load single group by ID
class GroupManagementLoadByIdRequested extends GroupManagementEvent {
  final int groupId;

  const GroupManagementLoadByIdRequested(this.groupId);

  @override
  List<Object> get props => [groupId];
}

/// Create new group
class GroupManagementCreateRequested extends GroupManagementEvent {
  final GroupCreateRequest request;

  const GroupManagementCreateRequested(this.request);

  @override
  List<Object> get props => [request];
}

/// Update existing group
class GroupManagementUpdateRequested extends GroupManagementEvent {
  final int groupId;
  final GroupUpdateRequest request;

  const GroupManagementUpdateRequested(this.groupId, this.request);

  @override
  List<Object> get props => [groupId, request];
}

/// Delete group
class GroupManagementDeleteRequested extends GroupManagementEvent {
  final int groupId;

  const GroupManagementDeleteRequested(this.groupId);

  @override
  List<Object> get props => [groupId];
}

/// Add members to group
class GroupManagementAddMembersRequested extends GroupManagementEvent {
  final int groupId;
  final List<int> userIds;

  const GroupManagementAddMembersRequested(this.groupId, this.userIds);

  @override
  List<Object> get props => [groupId, userIds];
}

/// Remove member from group
class GroupManagementRemoveMemberRequested extends GroupManagementEvent {
  final int groupId;
  final int userId;

  const GroupManagementRemoveMemberRequested(this.groupId, this.userId);

  @override
  List<Object> get props => [groupId, userId];
}
