import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';
import 'package:smartphone_client_app/core/ui/widgets/widgets.dart';
import 'package:smartphone_client_app/core/utils/utils.dart';
import 'package:smartphone_client_app/features/device/data/models/device.dart';
import 'bloc/bloc.dart';

class MyDevicesScreen extends StatelessWidget {
  const MyDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceBloc()..add(const DeviceLoadRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Devices')),
        body: SafeArea(
          child: BlocConsumer<DeviceBloc, DeviceState>(
            listener: (context, state) {
              if (state is DeviceDeleted) {
                SnackbarHelper.showSuccess(
                  context,
                  'Device revoked successfully',
                );
              } else if (state is DeviceError && state is! DeviceDeleting) {
                // Only show error snackbar if not during deletion
                // (deletion errors will be handled differently)
              }
            },
            builder: (context, state) {
              if (state is DeviceLoading) {
                return const LoadingState();
              }

              if (state is DeviceError) {
                return ErrorState(
                  title: 'Failed to load devices',
                  message: state.message.replaceAll('Exception: ', ''),
                  onRetry: () => context.read<DeviceBloc>().add(
                    const DeviceLoadRequested(),
                  ),
                );
              }

              if (state is DeviceLoaded) {
                if (state.devices.isEmpty) {
                  return const EmptyState(
                    icon: Icons.devices_other,
                    title: 'No Devices',
                    message: 'You have no registered devices',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final completer = Completer<void>();
                    context.read<DeviceBloc>().add(
                      DeviceRefreshRequested(completer),
                    );
                    await completer.future;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.devices.length,
                    itemBuilder: (context, index) {
                      final device = state.devices[index];
                      final isCurrentDevice =
                          device.id == state.currentDeviceId;

                      return _DeviceCard(
                        device: device,
                        isCurrentDevice: isCurrentDevice,
                        onRevoke: () => _showRevokeDialog(context, device),
                      );
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

  Future<void> _showRevokeDialog(BuildContext context, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 48,
        ),
        title: const Text('Revoke Device?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to revoke "${device.name}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('This action cannot be undone.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<DeviceBloc>().add(DeviceDeleteRequested(device.id));
    }
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final bool isCurrentDevice;
  final VoidCallback onRevoke;

  const _DeviceCard({
    required this.device,
    required this.isCurrentDevice,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentDevice
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentDevice
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrentDevice ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: isCurrentDevice
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentDevice
                                        ? colorScheme.primary
                                        : null,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentDevice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'This Device',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${device.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  icon: Icons.schedule,
                  label: 'Registered',
                  value: DateFormatter.formatRelativeDate(device.createdAt),
                ),
                _InfoChip(
                  icon: Icons.access_time,
                  label: 'Last Used',
                  value: DateFormatter.formatRelativeDate(device.lastUsedAt),
                ),
              ],
            ),

            if (!isCurrentDevice) const SizedBox(height: 16),
            if (!isCurrentDevice)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Revoke Device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
