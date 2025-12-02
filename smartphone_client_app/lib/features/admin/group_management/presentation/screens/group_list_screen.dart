import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import '../bloc/group_management_bloc.dart';
import '../bloc/group_management_event.dart';
import '../bloc/group_management_state.dart';
import '../widgets/group_list_item.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<GroupManagementBloc>().add(GroupManagementLoadAllRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter groups based on search query
  List<Group> _filterGroups(List<Group> groups) {
    if (_searchController.text.isEmpty) {
      return groups;
    }

    final query = _searchController.text.toLowerCase();
    return groups.where((group) {
      final nameMatch = group.name.toLowerCase().contains(query);
      final descMatch =
          group.description?.toLowerCase().contains(query) ?? false;
      return nameMatch || descMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {}); // Refresh to show all groups
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
                setState(() {}); // Rebuild to filter groups
              },
            ),
          ),
        ),
      ),
      body: BlocListener<GroupManagementBloc, GroupManagementState>(
        listener: (context, state) {
          // Show success message
          if (state is GroupManagementOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Show error message
          if (state is GroupManagementError) {
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
        child: BlocBuilder<GroupManagementBloc, GroupManagementState>(
          builder: (context, state) {
          // Handle loading state
          if (state is GroupManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          if (state is GroupManagementError) {
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
                      context.read<GroupManagementBloc>().add(
                        const GroupManagementLoadAllRequested(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Handle loaded state
          if (state is GroupManagementLoaded) {
            if (state.groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No groups yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create your first group',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final filteredGroups = _filterGroups(state.groups);
            if (filteredGroups.isEmpty) {
              return const Center(child: Text('No groups match your search'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                final completer = Completer<void>();
                context.read<GroupManagementBloc>().add(
                      GroupManagementRefreshRequested(completer),
                    );
                return completer.future;
              },
              child: ListView.builder(
                itemCount: filteredGroups.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final group = filteredGroups[index];
                  return GroupListItem(
                    group: group,
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/admin/groups/detail',
                        arguments: group.id,
                      );
                      // Reload if data was modified
                      if (result == true && context.mounted) {
                        context.read<GroupManagementBloc>().add(
                              const GroupManagementLoadAllRequested(),
                            );
                      }
                    },
                  );
                },
              ),
            );
          }

          // Handle operation success (after create/update/delete)
          if (state is GroupManagementOperationSuccess &&
              state.groups != null) {
            final filteredGroups = _filterGroups(state.groups!);
            if (filteredGroups.isEmpty) {
              return const Center(child: Text('No groups match your search'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                final completer = Completer<void>();
                context.read<GroupManagementBloc>().add(
                      GroupManagementRefreshRequested(completer),
                    );
                return completer.future;
              },
              child: ListView.builder(
                itemCount: filteredGroups.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final group = filteredGroups[index];
                  return GroupListItem(
                    group: group,
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/admin/groups/detail',
                        arguments: group.id,
                      );
                      // Reload if data was modified
                      if (result == true && context.mounted) {
                        context.read<GroupManagementBloc>().add(
                              const GroupManagementLoadAllRequested(),
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
            child: Text('Press the button below to load groups'),
          );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/admin/groups/create');
          // Reload if group was created
          if (result == true && context.mounted) {
            context.read<GroupManagementBloc>().add(
                  const GroupManagementLoadAllRequested(),
                );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }
}
