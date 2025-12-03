import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import 'package:smartphone_client_app/core/ui/widgets/gravatar_avatar.dart';
import 'package:smartphone_client_app/features/admin/group_management/presentation/bloc/group_management_bloc.dart';
import 'package:smartphone_client_app/features/admin/group_management/presentation/bloc/group_management_event.dart';
import 'package:smartphone_client_app/features/admin/group_management/presentation/bloc/group_management_state.dart';
import 'package:smartphone_client_app/features/admin/user_management/data/api/admin_user_api_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final Group group;

  const GroupMembersScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<User> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final apiService = AdminUserApiService();
      final allUsers = await apiService.getAllUsers();

      // Filter out users who are already members
      final currentMemberIds = widget.group.members?.map((m) => m.id).toSet() ?? {};
      setState(() {
        _availableUsers = allUsers.where((user) => !currentMemberIds.contains(user.id)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMembersDialog() {
    if (_availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All users are already members of this group'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _AddMembersDialog(
        availableUsers: _availableUsers,
        onAdd: (selectedUserIds) {
          if (selectedUserIds.isNotEmpty) {
            context.read<GroupManagementBloc>().add(
                  GroupManagementAddMembersRequested(
                    widget.group.id,
                    selectedUserIds,
                  ),
                );
          }
        },
      ),
    );
  }

  void _confirmRemoveMember(User member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove "${member.fullName}" from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GroupManagementBloc>().add(
                    GroupManagementRemoveMemberRequested(
                      widget.group.id,
                      member.id,
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupManagementBloc, GroupManagementState>(
      listener: (context, state) {
        if (state is GroupManagementOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Reload group details to get updated members list
          context.read<GroupManagementBloc>().add(
                GroupManagementLoadByIdRequested(widget.group.id),
              );
        } else if (state is GroupManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Members'),
        ),
        body: BlocBuilder<GroupManagementBloc, GroupManagementState>(
          builder: (context, state) {
            // Show updated members if we just loaded the group
            List<User>? currentMembers = widget.group.members;
            if (state is GroupManagementDetailLoaded) {
              currentMembers = state.group.members;
            }

            if (currentMembers == null || currentMembers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No members yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap + to add members to this group'),
                  ],
                ),
              );
            }

            return ListView(
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
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.groups,
                            size: 28,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.group.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentMembers.length} member${currentMembers.length == 1 ? '' : 's'}',
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

                // Members List
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...currentMembers.map((member) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: GravatarAvatar(
                          email: member.email,
                          radius: 20,
                        ),
                        title: Text(member.fullName),
                        subtitle: Text(member.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          tooltip: 'Remove member',
                          onPressed: () => _confirmRemoveMember(member),
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddMembersDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Members'),
        ),
      ),
    );
  }
}

class _AddMembersDialog extends StatefulWidget {
  final List<User> availableUsers;
  final Function(List<int>) onAdd;

  const _AddMembersDialog({
    required this.availableUsers,
    required this.onAdd,
  });

  @override
  State<_AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<_AddMembersDialog> {
  final Set<int> _selectedUserIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return widget.availableUsers;

    final query = _searchQuery.toLowerCase();
    return widget.availableUsers.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

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
                          'Add Members',
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
                      hintText: 'Search users...',
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

            // User List
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No users available'
                            : 'No users found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = _selectedUserIds.contains(user.id);

                        return CheckboxListTile(
                          secondary: GravatarAvatar(
                            email: user.email,
                            radius: 20,
                          ),
                          title: Text(user.fullName),
                          subtitle: Text(user.email),
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedUserIds.add(user.id);
                              } else {
                                _selectedUserIds.remove(user.id);
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
                    '${_selectedUserIds.length} selected',
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
                    onPressed: _selectedUserIds.isEmpty
                        ? null
                        : () {
                            widget.onAdd(_selectedUserIds.toList());
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
