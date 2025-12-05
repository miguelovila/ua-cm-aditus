import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_event.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_state.dart';

class DoorDetailScreen extends StatefulWidget {
  final int doorId;

  const DoorDetailScreen({
    super.key,
    required this.doorId,
  });

  @override
  State<DoorDetailScreen> createState() => _DoorDetailScreenState();
}

class _DoorDetailScreenState extends State<DoorDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadDoorDetails();
  }

  void _loadDoorDetails() {
    context.read<DoorManagementBloc>().add(
          DoorManagementLoadByIdRequested(widget.doorId),
        );
  }

  void _showDeleteConfirmation(BuildContext context, Door door) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Door'),
        content: Text(
          'Are you sure you want to delete "${door.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DoorManagementBloc>().add(
                    DoorManagementDeleteRequested(widget.doorId),
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
    return BlocListener<DoorManagementBloc, DoorManagementState>(
      listener: (context, state) {
        if (state is DoorManagementOperationSuccess) {
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
        } else if (state is DoorManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<DoorManagementBloc, DoorManagementState>(
        builder: (context, state) {
          if (state is DoorManagementDetailLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Door Details'),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is DoorManagementError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Door Details'),
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
                      onPressed: _loadDoorDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is DoorManagementDetailLoaded) {
            final door = state.door;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Door Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/admin/doors/edit',
                        arguments: door,
                      );
                      // Reload if door was edited
                      if (result == true && context.mounted) {
                        _loadDoorDetails();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteConfirmation(context, door),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  _loadDoorDetails();
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
                                color: door.isActive
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.door_front_door,
                                size: 48,
                                color: door.isActive
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              door.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            if (door.location != null && door.location!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                door.location!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: door.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                door.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: door.isActive
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Cards (if backend provides counts)
                    if (door.allowedUserCount != null ||
                        door.allowedGroupCount != null ||
                        door.exceptionUserCount != null ||
                        door.exceptionGroupCount != null)
                      Column(
                        children: [
                          Row(
                            children: [
                              if (door.allowedUserCount != null)
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
                                            '${door.allowedUserCount}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Users',
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
                              if (door.allowedUserCount != null &&
                                  door.allowedGroupCount != null)
                                const SizedBox(width: 8),
                              if (door.allowedGroupCount != null)
                                Expanded(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.groups,
                                            size: 32,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${door.allowedGroupCount}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Groups',
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
                          const SizedBox(height: 8),
                          if (door.exceptionUserCount != null ||
                              door.exceptionGroupCount != null)
                            Row(
                              children: [
                                if (door.exceptionUserCount != null)
                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.block,
                                              size: 32,
                                              color: Colors.red[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${door.exceptionUserCount}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'User Exceptions',
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
                                if (door.exceptionUserCount != null &&
                                    door.exceptionGroupCount != null)
                                  const SizedBox(width: 8),
                                if (door.exceptionGroupCount != null)
                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.block,
                                              size: 32,
                                              color: Colors.red[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${door.exceptionGroupCount}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Group Exceptions',
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
                        ],
                      ),

                    // Action Cards
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.vpn_key),
                            title: const Text('Manage Access Control'),
                            subtitle: const Text('Configure user and group permissions'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/admin/doors/access',
                                arguments: door,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Access Logs'),
                            subtitle: const Text('View door access history'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Access logs coming soon'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Door Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Door Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'Door ID',
                              value: '#${door.id}',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Name',
                              value: door.name,
                            ),
                            if (door.location != null && door.location!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Location',
                                value: door.location!,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Status',
                              value: door.isActive ? 'Active' : 'Inactive',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            if (door.deviceId != null && door.deviceId!.isNotEmpty) ...[
                              _InfoRow(
                                label: 'Device ID (BLE)',
                                value: door.deviceId!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (door.description != null && door.description!.isNotEmpty) ...[
                              _InfoRow(
                                label: 'Description',
                                value: door.description!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            _InfoRow(
                              label: 'Created',
                              value: _formatDate(door.createdAt),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Last Updated',
                              value: _formatDate(door.updatedAt),
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
              title: const Text('Door Details'),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
