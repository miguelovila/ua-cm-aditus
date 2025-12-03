import 'package:flutter/material.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import 'package:smartphone_client_app/features/admin/group_management/data/api/admin_group_api_service.dart';
import 'package:smartphone_client_app/features/admin/user_management/data/api/admin_user_api_service.dart';

class UserGroupsScreen extends StatefulWidget {
  final User user;

  const UserGroupsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserGroupsScreen> createState() => _UserGroupsScreenState();
}

class _UserGroupsScreenState extends State<UserGroupsScreen> {
  final AdminGroupApiService _groupApiService = AdminGroupApiService();
  final AdminUserApiService _userApiService = AdminUserApiService();
  List<Group> _availableGroups = [];
  List<Group> _currentGroups = [];
  bool _loadingGroups = false;
  bool _loadingUser = false;

  @override
  void initState() {
    super.initState();
    _currentGroups = widget.user.groups ?? [];
    _loadAvailableGroups();
  }

  Future<void> _loadAvailableGroups() async {
    setState(() => _loadingGroups = true);
    try {
      final allGroups = await _groupApiService.getAllGroups();

      // Filter out groups user is already a member of
      final currentGroupIds = _currentGroups.map((g) => g.id).toSet();
      setState(() {
        _availableGroups =
            allGroups.where((group) => !currentGroupIds.contains(group.id)).toList();
        _loadingGroups = false;
      });
    } catch (e) {
      setState(() => _loadingGroups = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reloadUserData() async {
    setState(() => _loadingUser = true);
    try {
      final updatedUser = await _userApiService.getUserById(widget.user.id);
      setState(() {
        _currentGroups = updatedUser.groups ?? [];
        _loadingUser = false;
      });
      // Reload available groups to update the list
      await _loadAvailableGroups();
    } catch (e) {
      setState(() => _loadingUser = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reload user data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddGroupsDialog() {
    if (_availableGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User is already a member of all available groups'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _AddGroupsDialog(
        availableGroups: _availableGroups,
        onAdd: (selectedGroupIds) async {
          if (selectedGroupIds.isNotEmpty) {
            await _addToGroups(selectedGroupIds);
          }
        },
      ),
    );
  }

  Future<void> _addToGroups(List<int> groupIds) async {
    try {
      // Add user to each selected group
      for (final groupId in groupIds) {
        await _groupApiService.addMembers(groupId, [widget.user.id]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added user to ${groupIds.length} group${groupIds.length == 1 ? '' : 's'}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload user data to get updated groups list
        await _reloadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to groups: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmRemoveFromGroup(Group group) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from Group'),
        content: Text(
          'Are you sure you want to remove "${widget.user.fullName}" from "${group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _removeFromGroup(group);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromGroup(Group group) async {
    try {
      await _groupApiService.removeMember(group.id, widget.user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from "${group.name}" successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload user data to get updated groups list
        await _reloadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from group: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Groups'),
      ),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : _currentGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Not a member of any groups',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap + to add user to groups'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 28,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user.fullName,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_currentGroups.length} group membership${_currentGroups.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Groups List
                    Text(
                      'Member Of',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    ..._currentGroups.map((group) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.groups,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            title: Text(group.name),
                            subtitle: group.description != null
                                ? Text(
                                    group.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              tooltip: 'Remove from group',
                              onPressed: () => _confirmRemoveFromGroup(group),
                            ),
                          ),
                        )),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingGroups ? null : _showAddGroupsDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add to Groups'),
      ),
    );
  }
}

class _AddGroupsDialog extends StatefulWidget {
  final List<Group> availableGroups;
  final Function(List<int>) onAdd;

  const _AddGroupsDialog({
    required this.availableGroups,
    required this.onAdd,
  });

  @override
  State<_AddGroupsDialog> createState() => _AddGroupsDialogState();
}

class _AddGroupsDialogState extends State<_AddGroupsDialog> {
  final Set<int> _selectedGroupIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Group> get _filteredGroups {
    if (_searchQuery.isEmpty) return widget.availableGroups;

    final query = _searchQuery.toLowerCase();
    return widget.availableGroups.where((group) {
      return group.name.toLowerCase().contains(query) ||
          (group.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _filteredGroups;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add to Groups',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search groups...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Group List
            Expanded(
              child: filteredGroups.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No groups available'
                            : 'No groups found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = filteredGroups[index];
                        final isSelected = _selectedGroupIds.contains(group.id);

                        return CheckboxListTile(
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.groups,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(group.name),
                          subtitle: group.description != null
                              ? Text(
                                  group.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedGroupIds.add(group.id);
                              } else {
                                _selectedGroupIds.remove(group.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            // Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_selectedGroupIds.length} selected',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedGroupIds.isEmpty
                        ? null
                        : () {
                            widget.onAdd(_selectedGroupIds.toList());
                            Navigator.pop(context);
                          },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
