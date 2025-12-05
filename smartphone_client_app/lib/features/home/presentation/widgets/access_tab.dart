import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../door_discovery/presentation/bloc/bloc.dart';
import '../../../door_discovery/presentation/widgets/discovered_door_card.dart';
import '../../../door_unlock/presentation/bloc/bloc.dart';
import '../../../../core/ui/widgets/widgets.dart';
import '../../../../core/ui/snackbar_helper.dart';

class AccessTab extends StatelessWidget {
  const AccessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DoorDiscoveryBloc()),
        BlocProvider(create: (context) => DoorUnlockBloc()),
      ],
      child: const _AccessTabContent(),
    );
  }
}

class _AccessTabContent extends StatefulWidget {
  const _AccessTabContent();

  @override
  State<_AccessTabContent> createState() => _AccessTabContentState();
}

class _AccessTabContentState extends State<_AccessTabContent> {
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoorUnlockBloc, DoorUnlockState>(
      listener: (context, state) {
        if (state is DoorUnlockInProgress) {
          if (!_isDialogShowing) {
            // Show progress dialog only once
            _isDialogShowing = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => BlocProvider.value(
                value: context.read<DoorUnlockBloc>(),
                child: _UnlockProgressDialog(),
              ),
            ).then((_) {
              // Dialog dismissed
              _isDialogShowing = false;
            });
          }
          // Dialog content will update automatically via BlocBuilder inside
        } else if (state is DoorUnlockSuccess) {
          if (_isDialogShowing) {
            // Dismiss progress dialog
            Navigator.of(context).pop();
            _isDialogShowing = false;
          }
          // Show success message
          SnackbarHelper.showSuccess(
            context,
            'Door "${state.doorName}" unlocked successfully!',
          );
        } else if (state is DoorUnlockFailure) {
          if (_isDialogShowing) {
            // Dismiss progress dialog
            Navigator.of(context).pop();
            _isDialogShowing = false;
          }
          // Show error message
          SnackbarHelper.showError(context, state.error);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Doors'),
        actions: [
          BlocBuilder<DoorDiscoveryBloc, DoorDiscoveryState>(
            builder: (context, state) {
              final isScanning = state is DoorDiscoveryScanning;

              return IconButton(
                onPressed: isScanning
                    ? () => context
                        .read<DoorDiscoveryBloc>()
                        .add(const StopScanRequested())
                    : () => context
                        .read<DoorDiscoveryBloc>()
                        .add(const StartScanRequested()),
                icon: Icon(isScanning ? Icons.stop : Icons.bluetooth_searching),
                tooltip: isScanning ? 'Stop Scan' : 'Scan for Doors',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DoorDiscoveryBloc, DoorDiscoveryState>(
        builder: (context, state) {
          return switch (state) {
            DoorDiscoveryInitial() => EmptyState(
                icon: Icons.bluetooth_searching,
                title: 'Ready to Scan',
                message: 'Tap the scan button to discover nearby doors',
                action: FilledButton.icon(
                  onPressed: () => context
                      .read<DoorDiscoveryBloc>()
                      .add(const StartScanRequested()),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Start Scanning'),
                ),
              ),
            DoorDiscoveryScanning(discoveredDoors: final doors) => Column(
                children: [
                  LinearProgressIndicator(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scanning for doors...',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: doors.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No doors found yet.\nMake sure you are near a door controller.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: doors.length,
                            itemBuilder: (context, index) {
                              return DiscoveredDoorCard(
                                door: doors[index],
                                onTap: () {
                                  // Show confirmation dialog
                                  showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      icon: Icon(
                                        Icons.lock_open,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 48,
                                      ),
                                      title: const Text('Unlock Door'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doors[index].name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text('Confirm to unlock this door.'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(dialogContext).pop(true),
                                          child: const Text('Unlock'),
                                        ),
                                      ],
                                    ),
                                  ).then((confirmed) {
                                    if (confirmed == true && context.mounted) {
                                      context.read<DoorUnlockBloc>().add(
                                            DoorUnlockRequested(
                                              doors[index].deviceId,
                                              doors[index].name,
                                            ),
                                          );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            DoorDiscoveryCompleted(discoveredDoors: final doors) =>
              doors.isEmpty
                  ? EmptyState(
                      icon: Icons.bluetooth_disabled,
                      title: 'No Doors Found',
                      message:
                          'No door controllers were detected nearby.\nMake sure Bluetooth is enabled.',
                      action: FilledButton.icon(
                        onPressed: () => context
                            .read<DoorDiscoveryBloc>()
                            .add(const StartScanRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: doors.length,
                      itemBuilder: (context, index) {
                        return DiscoveredDoorCard(
                          door: doors[index],
                          onTap: () {
                            // Show confirmation dialog
                            showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                icon: Icon(
                                  Icons.lock_open,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 48,
                                ),
                                title: const Text('Unlock Door'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doors[index].name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Confirm to unlock this door.'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('Unlock'),
                                  ),
                                ],
                              ),
                            ).then((confirmed) {
                              if (confirmed == true && context.mounted) {
                                context.read<DoorUnlockBloc>().add(
                                      DoorUnlockRequested(
                                        doors[index].deviceId,
                                        doors[index].name,
                                      ),
                                    );
                              }
                            });
                          },
                        );
                      },
                    ),
            DoorDiscoveryError(message: final message) => ErrorState(
                title: 'Scan Failed',
                message: message,
                onRetry: () => context
                    .read<DoorDiscoveryBloc>()
                    .add(const StartScanRequested()),
              ),
          };
        },
      ),
      ),
    );
  }
}

class _UnlockProgressDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoorUnlockBloc, DoorUnlockState>(
      builder: (context, state) {
        // Determine the status message and icon
        final String statusMessage;
        final IconData statusIcon;

        if (state is DoorUnlockInProgress) {
          statusMessage = state.status;
          statusIcon = _getIconForStatus(state.status);
        } else {
          statusMessage = 'Processing...';
          statusIcon = Icons.lock_open;
        }

        return PopScope(
          canPop: false, // Prevent back button dismissal
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  statusMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForStatus(String status) {
    if (status.contains('Preparing')) return Icons.pending;
    if (status.contains('Connecting')) return Icons.bluetooth_connected;
    if (status.contains('Discovering')) return Icons.search;
    if (status.contains('Authenticating')) return Icons.verified_user;
    if (status.contains('Signing')) return Icons.lock_clock;
    if (status.contains('Unlocking')) return Icons.lock_open;
    return Icons.lock_open;
  }
}
