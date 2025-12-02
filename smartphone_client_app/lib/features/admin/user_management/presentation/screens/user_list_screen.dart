import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import '../bloc/user_management_bloc.dart';
import '../bloc/user_management_event.dart';
import '../bloc/user_management_state.dart';
import '../widgets/user_list_item.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all'; // 'all', 'admin', 'user'

  @override
  void initState() {
    super.initState();
    context.read<UserManagementBloc>().add(const UserManagementLoadAllRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter users based on search query and role
  List<User> _filterUsers(List<User> users) {
    var filtered = users;

    // Filter by role
    if (_selectedRole != 'all') {
      filtered = filtered.where((user) => user.role == _selectedRole).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        final nameMatch = user.fullName.toLowerCase().contains(query);
        final emailMatch = user.email.toLowerCase().contains(query);
        return nameMatch || emailMatch;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserManagementBloc, UserManagementState>(
      listener: (context, state) {
        // Show success message
        if (state is UserManagementOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Show error message
        if (state is UserManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                // Role filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedRole == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _selectedRole = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Admins'),
                        selected: _selectedRole == 'admin',
                        onSelected: (selected) {
                          setState(() {
                            _selectedRole = 'admin';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Users'),
                        selected: _selectedRole == 'user',
                        onSelected: (selected) {
                          setState(() {
                            _selectedRole = 'user';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<UserManagementBloc, UserManagementState>(
          builder: (context, state) {
            // Handle loading state
            if (state is UserManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle error state
            if (state is UserManagementError) {
              return Center(
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
                      onPressed: () {
                        context.read<UserManagementBloc>().add(
                              const UserManagementLoadAllRequested(),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Handle loaded state
            if (state is UserManagementLoaded) {
              if (state.users.isEmpty) {
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
                      Text(
                        'No users yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first user',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final filteredUsers = _filterUsers(state.users);
              if (filteredUsers.isEmpty) {
                return const Center(child: Text('No users match your search'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final completer = Completer<void>();
                  context.read<UserManagementBloc>().add(
                        UserManagementRefreshRequested(completer),
                      );
                  return completer.future;
                },
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return UserListItem(
                      user: user,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/admin/users/detail',
                          arguments: user.id,
                        );
                        // Reload if data was modified
                        if (result == true && context.mounted) {
                          context.read<UserManagementBloc>().add(
                                const UserManagementLoadAllRequested(),
                              );
                        }
                      },
                    );
                  },
                ),
              );
            }

            // Handle operation success (after create/update/delete)
            if (state is UserManagementOperationSuccess && state.users != null) {
              final filteredUsers = _filterUsers(state.users!);
              if (filteredUsers.isEmpty) {
                return const Center(child: Text('No users match your search'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final completer = Completer<void>();
                  context.read<UserManagementBloc>().add(
                        UserManagementRefreshRequested(completer),
                      );
                  return completer.future;
                },
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return UserListItem(
                      user: user,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/admin/users/detail',
                          arguments: user.id,
                        );
                        // Reload if data was modified
                        if (result == true && context.mounted) {
                          context.read<UserManagementBloc>().add(
                                const UserManagementLoadAllRequested(),
                              );
                        }
                      },
                    );
                  },
                ),
              );
            }

            // Default/initial state
            return const Center(
              child: Text('Press the button below to load users'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/admin/users/create');
            // Reload if user was created
            if (result == true && context.mounted) {
              context.read<UserManagementBloc>().add(
                    const UserManagementLoadAllRequested(),
                  );
            }
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Create User'),
        ),
      ),
    );
  }
}
