import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../bloc/group_management_bloc.dart';
import '../bloc/group_management_event.dart';
import '../bloc/group_management_state.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  void _loadGroupDetails() {
    context.read<GroupManagementBloc>().add(
          GroupManagementLoadByIdRequested(widget.groupId),
        );
  }

  void _showDeleteConfirmation(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
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
                    GroupManagementDeleteRequested(widget.groupId),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
          // If deleted, go back to list with success result
          if (state.message.contains('deleted')) {
            Navigator.pop(context, true);
          }
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
      child: BlocBuilder<GroupManagementBloc, GroupManagementState>(
        builder: (context, state) {
          if (state is GroupManagementDetailLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Group Details'),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is GroupManagementError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Group Details'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGroupDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is GroupManagementDetailLoaded) {
            final group = state.group;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Group Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/admin/groups/edit',
                        arguments: group,
                      );
                      // Reload if group was edited
                      if (result == true && context.mounted) {
                        _loadGroupDetails();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteConfirmation(context, group),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  _loadGroupDetails();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.groups,
                                size: 48,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              group.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            if (group.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                group.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 32,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${group.memberCount}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Members',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.door_front_door,
                                    size: 32,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${group.doorCount}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Doors',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Cards
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_add),
                            title: const Text('Manage Members'),
                            subtitle: Text('Add or remove users from this group'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to members management
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Member management coming soon'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.vpn_key),
                            title: const Text('Manage Door Access'),
                            subtitle: Text('Configure which doors this group can access'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to door access management
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Door access management coming soon'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'Created',
                              value: _formatDate(group.createdAt),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Last Updated',
                              value: _formatDate(group.updatedAt),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Group ID',
                              value: '#${group.id}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Fallback
          return Scaffold(
            appBar: AppBar(
              title: const Text('Group Details'),
            ),
            body: const Center(
              child: Text('Loading...'),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
