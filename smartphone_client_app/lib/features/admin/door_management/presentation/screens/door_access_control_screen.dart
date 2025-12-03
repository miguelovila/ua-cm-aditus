import 'package:flutter/material.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/core/api/access_control_api_service.dart';
import 'package:smartphone_client_app/features/admin/user_management/data/api/admin_user_api_service.dart';
import 'package:smartphone_client_app/features/admin/group_management/data/api/admin_group_api_service.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';

class DoorAccessControlScreen extends StatefulWidget {
  final Door door;

  const DoorAccessControlScreen({
    super.key,
    required this.door,
  });

  @override
  State<DoorAccessControlScreen> createState() =>
      _DoorAccessControlScreenState();
}

class _DoorAccessControlScreenState extends State<DoorAccessControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AccessControlApiService _accessControlApi = AccessControlApiService();
  final AdminUserApiService _userApi = AdminUserApiService();
  final AdminGroupApiService _groupApi = AdminGroupApiService();

  AccessRule? _accessRules;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAccessRules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessRules() async {
    setState(() => _loading = true);
    try {
      final rules = await _accessControlApi.getAccessRules(widget.door.id);
      setState(() {
        _accessRules = rules;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load access rules: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Control'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Allowed Users'),
            Tab(text: 'Allowed Groups'),
            Tab(text: 'User Exceptions'),
            Tab(text: 'Group Exceptions'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accessRules == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text('Failed to load access rules'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAccessRules,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _AllowedUsersTab(
                      doorId: widget.door.id,
                      allowedUsers: _accessRules!.allowedUsers,
                      onRefresh: _loadAccessRules,
                      accessControlApi: _accessControlApi,
                      userApi: _userApi,
                      onSuccess: _showSuccessSnackBar,
                      onError: _showErrorSnackBar,
                    ),
                    _AllowedGroupsTab(
                      doorId: widget.door.id,
                      allowedGroups: _accessRules!.allowedGroups,
                      onRefresh: _loadAccessRules,
                      accessControlApi: _accessControlApi,
                      groupApi: _groupApi,
                      onSuccess: _showSuccessSnackBar,
                      onError: _showErrorSnackBar,
                    ),
                    _UserExceptionsTab(
                      doorId: widget.door.id,
                      exceptionUsers: _accessRules!.exceptionUsers,
                      onRefresh: _loadAccessRules,
                      accessControlApi: _accessControlApi,
                      userApi: _userApi,
                      onSuccess: _showSuccessSnackBar,
                      onError: _showErrorSnackBar,
                    ),
                    _GroupExceptionsTab(
                      doorId: widget.door.id,
                      exceptionGroups: _accessRules!.exceptionGroups,
                      onRefresh: _loadAccessRules,
                      accessControlApi: _accessControlApi,
                      groupApi: _groupApi,
                      onSuccess: _showSuccessSnackBar,
                      onError: _showErrorSnackBar,
                    ),
                  ],
                ),
    );
  }
}

// Allowed Users Tab
class _AllowedUsersTab extends StatelessWidget {
  final int doorId;
  final List<SimpleUser> allowedUsers;
  final VoidCallback onRefresh;
  final AccessControlApiService accessControlApi;
  final AdminUserApiService userApi;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AllowedUsersTab({
    required this.doorId,
    required this.allowedUsers,
    required this.onRefresh,
    required this.accessControlApi,
    required this.userApi,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> _addUser(BuildContext context) async {
    try {
      final allUsers = await userApi.getAllUsers();
      final allowedUserIds = allowedUsers.map((u) => u.id).toSet();
      final availableUsers =
          allUsers.where((u) => !allowedUserIds.contains(u.id)).toList();

      if (availableUsers.isEmpty) {
        onError('All users already have access');
        return;
      }

      if (context.mounted) {
        final selectedUser = await showDialog<User>(
          context: context,
          builder: (context) =>
              _SelectUserDialog(availableUsers: availableUsers),
        );

        if (selectedUser != null) {
          await accessControlApi.grantUserAccess(doorId, selectedUser.id);
          onSuccess('Access granted to ${selectedUser.email}');
          onRefresh();
        }
      }
    } catch (e) {
      onError('Failed to add user: $e');
    }
  }

  Future<void> _removeUser(BuildContext context, SimpleUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Remove direct access for "${user.email}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await accessControlApi.revokeUserAccess(doorId, user.id);
        onSuccess('Access revoked for ${user.email}');
        onRefresh();
      } catch (e) {
        onError('Failed to revoke access: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (allowedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No users with direct access'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _addUser(context),
              icon: const Icon(Icons.add),
              label: const Text('Grant Access'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${allowedUsers.length} user${allowedUsers.length == 1 ? '' : 's'} with direct access',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addUser(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allowedUsers.length,
            itemBuilder: (context, index) {
              final user = allowedUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () => _removeUser(context, user),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Allowed Groups Tab
class _AllowedGroupsTab extends StatelessWidget {
  final int doorId;
  final List<SimpleGroup> allowedGroups;
  final VoidCallback onRefresh;
  final AccessControlApiService accessControlApi;
  final AdminGroupApiService groupApi;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AllowedGroupsTab({
    required this.doorId,
    required this.allowedGroups,
    required this.onRefresh,
    required this.accessControlApi,
    required this.groupApi,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> _addGroup(BuildContext context) async {
    try {
      final allGroups = await groupApi.getAllGroups();
      final allowedGroupIds = allowedGroups.map((g) => g.id).toSet();
      final availableGroups =
          allGroups.where((g) => !allowedGroupIds.contains(g.id)).toList();

      if (availableGroups.isEmpty) {
        onError('All groups already have access');
        return;
      }

      if (context.mounted) {
        final selectedGroup = await showDialog<Group>(
          context: context,
          builder: (context) =>
              _SelectGroupDialog(availableGroups: availableGroups),
        );

        if (selectedGroup != null) {
          await accessControlApi.grantGroupAccess(doorId, selectedGroup.id);
          onSuccess('Access granted to ${selectedGroup.name}');
          onRefresh();
        }
      }
    } catch (e) {
      onError('Failed to add group: $e');
    }
  }

  Future<void> _removeGroup(BuildContext context, SimpleGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Remove access for "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await accessControlApi.revokeGroupAccess(doorId, group.id);
        onSuccess('Access revoked for ${group.name}');
        onRefresh();
      } catch (e) {
        onError('Failed to revoke access: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (allowedGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No groups with access'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _addGroup(context),
              icon: const Icon(Icons.add),
              label: const Text('Grant Access'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${allowedGroups.length} group${allowedGroups.length == 1 ? '' : 's'} with access',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addGroup(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allowedGroups.length,
            itemBuilder: (context, index) {
              final group = allowedGroups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.groups),
                  ),
                  title: Text(group.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () => _removeGroup(context, group),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// User Exceptions Tab (Blacklist)
class _UserExceptionsTab extends StatelessWidget {
  final int doorId;
  final List<SimpleUser> exceptionUsers;
  final VoidCallback onRefresh;
  final AccessControlApiService accessControlApi;
  final AdminUserApiService userApi;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _UserExceptionsTab({
    required this.doorId,
    required this.exceptionUsers,
    required this.onRefresh,
    required this.accessControlApi,
    required this.userApi,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> _addException(BuildContext context) async {
    try {
      final allUsers = await userApi.getAllUsers();
      final exceptionUserIds = exceptionUsers.map((u) => u.id).toSet();
      final availableUsers =
          allUsers.where((u) => !exceptionUserIds.contains(u.id)).toList();

      if (availableUsers.isEmpty) {
        onError('All users are already in exceptions');
        return;
      }

      if (context.mounted) {
        final selectedUser = await showDialog<User>(
          context: context,
          builder: (context) =>
              _SelectUserDialog(availableUsers: availableUsers),
        );

        if (selectedUser != null) {
          await accessControlApi.addUserException(doorId, selectedUser.id);
          onSuccess('${selectedUser.email} added to blacklist');
          onRefresh();
        }
      }
    } catch (e) {
      onError('Failed to add exception: $e');
    }
  }

  Future<void> _removeException(BuildContext context, SimpleUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Blacklist'),
        content: Text('Remove "${user.email}" from blacklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await accessControlApi.removeUserException(doorId, user.id);
        onSuccess('${user.email} removed from blacklist');
        onRefresh();
      } catch (e) {
        onError('Failed to remove exception: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exceptionUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No blacklisted users'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _addException(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Exception'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${exceptionUsers.length} blacklisted user${exceptionUsers.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addException(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exceptionUsers.length,
            itemBuilder: (context, index) {
              final user = exceptionUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeException(context, user),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Group Exceptions Tab (Blacklist)
class _GroupExceptionsTab extends StatelessWidget {
  final int doorId;
  final List<SimpleGroup> exceptionGroups;
  final VoidCallback onRefresh;
  final AccessControlApiService accessControlApi;
  final AdminGroupApiService groupApi;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _GroupExceptionsTab({
    required this.doorId,
    required this.exceptionGroups,
    required this.onRefresh,
    required this.accessControlApi,
    required this.groupApi,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> _addException(BuildContext context) async {
    try {
      final allGroups = await groupApi.getAllGroups();
      final exceptionGroupIds = exceptionGroups.map((g) => g.id).toSet();
      final availableGroups =
          allGroups.where((g) => !exceptionGroupIds.contains(g.id)).toList();

      if (availableGroups.isEmpty) {
        onError('All groups are already in exceptions');
        return;
      }

      if (context.mounted) {
        final selectedGroup = await showDialog<Group>(
          context: context,
          builder: (context) =>
              _SelectGroupDialog(availableGroups: availableGroups),
        );

        if (selectedGroup != null) {
          await accessControlApi.addGroupException(doorId, selectedGroup.id);
          onSuccess('${selectedGroup.name} added to blacklist');
          onRefresh();
        }
      }
    } catch (e) {
      onError('Failed to add exception: $e');
    }
  }

  Future<void> _removeException(
      BuildContext context, SimpleGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Blacklist'),
        content: Text('Remove "${group.name}" from blacklist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await accessControlApi.removeGroupException(doorId, group.id);
        onSuccess('${group.name} removed from blacklist');
        onRefresh();
      } catch (e) {
        onError('Failed to remove exception: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (exceptionGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No blacklisted groups'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _addException(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Exception'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${exceptionGroups.length} blacklisted group${exceptionGroups.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addException(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: exceptionGroups.length,
            itemBuilder: (context, index) {
              final group = exceptionGroups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: Text(group.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeException(context, group),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Selection Dialogs
class _SelectUserDialog extends StatelessWidget {
  final List<User> availableUsers;

  const _SelectUserDialog({required this.availableUsers});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select User'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableUsers.length,
          itemBuilder: (context, index) {
            final user = availableUsers[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.email),
              subtitle: Text(user.fullName),
              onTap: () => Navigator.pop(context, user),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SelectGroupDialog extends StatelessWidget {
  final List<Group> availableGroups;

  const _SelectGroupDialog({required this.availableGroups});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Group'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableGroups.length,
          itemBuilder: (context, index) {
            final group = availableGroups[index];
            return ListTile(
              leading: const Icon(Icons.groups),
              title: Text(group.name),
              subtitle:
                  group.description != null ? Text(group.description!) : null,
              onTap: () => Navigator.pop(context, group),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
