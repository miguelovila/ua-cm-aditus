import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/ui/widgets/widgets.dart';
import 'package:smartphone_client_app/core/utils/utils.dart';
import 'package:smartphone_client_app/features/group/data/models/group.dart';
import 'bloc/bloc.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupBloc()..add(const GroupLoadRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Groups')),
        body: SafeArea(
          child: BlocBuilder<GroupBloc, GroupState>(
            builder: (context, state) {
              if (state is GroupLoading) {
                return const LoadingState();
              }

              if (state is GroupError) {
                return ErrorState(
                  title: 'Failed to load groups',
                  message: state.message.replaceAll('Exception: ', ''),
                  onRetry: () =>
                      context.read<GroupBloc>().add(const GroupLoadRequested()),
                );
              }

              if (state is GroupLoaded) {
                if (state.groups.isEmpty) {
                  return const EmptyState(
                    icon: Icons.group_outlined,
                    title: 'No Groups',
                    message: 'You are not a member of any groups',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final completer = Completer<void>();
                    context.read<GroupBloc>().add(
                      GroupRefreshRequested(completer),
                    );
                    await completer.future;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.groups.length,
                    itemBuilder: (context, index) {
                      return _GroupCard(group: state.groups[index]);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (group.description != null &&
                          group.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          group.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistics row
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    icon: Icons.people,
                    label:
                        '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    icon: Icons.door_front_door,
                    label:
                        '${group.doorCount} ${group.doorCount == 1 ? 'door' : 'doors'}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Created date
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Created ${DateFormatter.formatRelativeDate(group.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
