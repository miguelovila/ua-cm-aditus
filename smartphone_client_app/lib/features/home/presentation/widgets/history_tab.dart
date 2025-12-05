import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../history/presentation/bloc/bloc.dart';
import '../../../../core/ui/widgets/widgets.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HistoryBloc()..add(const LoadHistoryRequested()),
      child: const _HistoryTabContent(),
    );
  }
}

class _HistoryTabContent extends StatefulWidget {
  const _HistoryTabContent();

  @override
  State<_HistoryTabContent> createState() => _HistoryTabContentState();
}

class _HistoryTabContentState extends State<_HistoryTabContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<HistoryBloc>().add(const LoadMoreHistoryRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access History'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<HistoryBloc>().add(const RefreshHistoryRequested());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryInitial || state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HistoryEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: 'No Access History',
              message: 'Your door access logs will appear here',
              action: FilledButton.icon(
                onPressed: () => context
                    .read<HistoryBloc>()
                    .add(const RefreshHistoryRequested()),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            );
          } else if (state is HistoryLoaded) {
            final logs = state.logs;
            final total = state.total;
            final hasMore = state.hasMore;
            final isLoadingMore = state.isLoadingMore;

            return RefreshIndicator(
                onRefresh: () async {
                  context.read<HistoryBloc>().add(const RefreshHistoryRequested());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: Column(
                  children: [
                    // Summary bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: $total access${total == 1 ? '' : 'es'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Showing ${logs.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: logs.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= logs.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }

                          final log = logs[index];
                          return _AccessLogCard(log: log);
                        },
                      ),
                    ),
                  ],
                ),
              );
          } else if (state is HistoryError) {
            return ErrorState(
              title: 'Failed to Load History',
              message: state.message,
              onRetry: () => context
                  .read<HistoryBloc>()
                  .add(const LoadHistoryRequested()),
            );
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}

class _AccessLogCard extends StatelessWidget {
  final dynamic log;

  const _AccessLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final bool success = log.success;
    final String doorName = log.door?.name ?? 'Unknown Door';
    final String? location = log.door?.location;
    final DateTime timestamp = log.timestamp;
    final String? failureReason = log.failureReason;

    final Color statusColor = success
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    final IconData statusIcon = success ? Icons.lock_open : Icons.error_outline;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          doorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (!success && failureReason != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatFailureReason(failureReason),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(
            success ? 'Success' : 'Failed',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide(color: statusColor, width: 1),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y HH:mm').format(timestamp);
    }
  }

  String _formatFailureReason(String reason) {
    return reason
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
