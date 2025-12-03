import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_event.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_state.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/widgets/door_list_item.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';

class DoorListScreen extends StatefulWidget {
  const DoorListScreen({super.key});

  @override
  State<DoorListScreen> createState() => _DoorListScreenState();
}

class _DoorListScreenState extends State<DoorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    context
        .read<DoorManagementBloc>()
        .add(const DoorManagementLoadAllRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Client-side filtering
  List<Door> _filterDoors(List<Door> doors) {
    var filtered = doors;

    // Filter by status
    if (_selectedStatus == 'active') {
      filtered = filtered.where((door) => door.isActive).toList();
    } else if (_selectedStatus == 'inactive') {
      filtered = filtered.where((door) => !door.isActive).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((door) {
        final nameMatch = door.name.toLowerCase().contains(query);
        final locationMatch =
            door.location?.toLowerCase().contains(query) ?? false;
        return nameMatch || locationMatch;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoorManagementBloc, DoorManagementState>(
      listener: (context, state) {
        // Show success message
        if (state is DoorManagementOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Show error message
        if (state is DoorManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {},
                textColor: Colors.white,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Door Management'),
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
                      hintText: 'Search doors...',
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
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                // Status filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Filter: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedStatus == 'all',
                        onSelected: (selected) {
                          setState(() => _selectedStatus = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Active'),
                        selected: _selectedStatus == 'active',
                        onSelected: (selected) {
                          setState(() => _selectedStatus = 'active');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Inactive'),
                        selected: _selectedStatus == 'inactive',
                        onSelected: (selected) {
                          setState(() => _selectedStatus = 'inactive');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<DoorManagementBloc, DoorManagementState>(
          builder: (context, state) {
            // Loading state
            if (state is DoorManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (state is DoorManagementError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DoorManagementBloc>().add(
                              const DoorManagementLoadAllRequested(),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Empty state
            if (state is DoorManagementLoaded && state.doors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.door_front_door_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No doors yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap + to create your first door'),
                  ],
                ),
              );
            }

            // Loaded state
            if (state is DoorManagementLoaded ||
                (state is DoorManagementOperationSuccess &&
                    state.doors != null)) {
              final doors = state is DoorManagementLoaded
                  ? state.doors
                  : (state as DoorManagementOperationSuccess).doors!;

              final filteredDoors = _filterDoors(doors);

              // Filtered empty state
              if (filteredDoors.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No doors found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text('Try adjusting your search or filters'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final completer = Completer<void>();
                  context.read<DoorManagementBloc>().add(
                        DoorManagementRefreshRequested(completer),
                      );
                  return completer.future;
                },
                child: ListView.builder(
                  itemCount: filteredDoors.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final door = filteredDoors[index];
                    return DoorListItem(
                      door: door,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/admin/doors/detail',
                          arguments: door.id,
                        );
                        // Reload if data was modified
                        if (result == true && context.mounted) {
                          context.read<DoorManagementBloc>().add(
                                const DoorManagementLoadAllRequested(),
                              );
                        }
                      },
                    );
                  },
                ),
              );
            }

            return const Center(
              child: Text('Press the button below to load doors'),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result =
                await Navigator.pushNamed(context, '/admin/doors/create');
            if (result == true && context.mounted) {
              context.read<DoorManagementBloc>().add(
                    const DoorManagementLoadAllRequested(),
                  );
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Door'),
        ),
      ),
    );
  }
}
