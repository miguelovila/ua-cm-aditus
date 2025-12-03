import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/ui/widgets/gravatar_avatar.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../bloc/user_management_bloc.dart';
import '../bloc/user_management_event.dart';
import '../bloc/user_management_state.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  void _loadUserDetails() {
    context.read<UserManagementBloc>().add(
          UserManagementLoadByIdRequested(widget.userId),
        );
  }

  void _showDeleteConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user.fullName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UserManagementBloc>().add(
                    UserManagementDeleteRequested(widget.userId),
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
    return BlocListener<UserManagementBloc, UserManagementState>(
      listener: (context, state) {
        if (state is UserManagementOperationSuccess) {
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
        } else if (state is UserManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state is UserManagementDetailLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('User Details'),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is UserManagementError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('User Details'),
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
                      onPressed: _loadUserDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is UserManagementDetailLoaded) {
            final user = state.user;
            final isAdmin = user.role == 'admin';

            return Scaffold(
              appBar: AppBar(
                title: const Text('User Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/admin/users/edit',
                        arguments: user,
                      );
                      // Reload if user was edited
                      if (result == true && context.mounted) {
                        _loadUserDetails();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteConfirmation(context, user),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  _loadUserDetails();
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
                            GravatarAvatar(
                              email: user.email,
                              radius: 40,
                              backgroundColor: isAdmin
                                  ? Colors.purple.shade100
                                  : Theme.of(context).colorScheme.primaryContainer,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? Colors.purple.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'ADMINISTRATOR' : 'USER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin
                                      ? Colors.purple.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                              'Account Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'User ID',
                              value: '#${user.id}',
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Email',
                              value: user.email,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Full Name',
                              value: user.fullName,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Role',
                              value: user.role.toUpperCase(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Cards
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.devices),
                            title: const Text('Manage Devices'),
                            subtitle: const Text('View and manage user devices'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/admin/users/devices',
                                arguments: user,
                              );
                              // Reload if devices were modified
                              if (result == true && context.mounted) {
                                _loadUserDetails();
                              }
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.groups),
                            title: const Text('Manage Groups'),
                            subtitle: const Text('View user groups and memberships'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/admin/users/groups',
                                arguments: user,
                              );
                              // Reload if groups were modified
                              if (result == true && context.mounted) {
                                _loadUserDetails();
                              }
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Access Logs'),
                            subtitle: const Text('View user access history'),
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
                  ],
                ),
              ),
            );
          }

          // Fallback
          return Scaffold(
            appBar: AppBar(
              title: const Text('User Details'),
            ),
            body: const Center(
              child: Text('Loading...'),
            ),
          );
        },
      ),
    );
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
