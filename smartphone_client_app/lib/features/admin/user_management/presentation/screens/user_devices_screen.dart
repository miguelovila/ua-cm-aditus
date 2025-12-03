import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import 'package:smartphone_client_app/features/device/data/models/device.dart';
import 'package:smartphone_client_app/core/api/device_api_service.dart';
import 'package:smartphone_client_app/features/admin/user_management/presentation/bloc/user_management_bloc.dart';
import 'package:smartphone_client_app/features/admin/user_management/presentation/bloc/user_management_event.dart';
import 'package:smartphone_client_app/features/admin/user_management/presentation/bloc/user_management_state.dart';

class UserDevicesScreen extends StatefulWidget {
  final User user;

  const UserDevicesScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDevicesScreen> createState() => _UserDevicesScreenState();
}

class _UserDevicesScreenState extends State<UserDevicesScreen> {
  final DeviceApiService _deviceApiService = DeviceApiService();
  bool _isRevoking = false;

  void _confirmRevokeDevice(Device device) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke Device'),
        content: Text(
          'Are you sure you want to revoke "${device.name}"? The user will need to register this device again to regain access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _revokeDevice(device);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeDevice(Device device) async {
    setState(() => _isRevoking = true);
    try {
      await _deviceApiService.deleteDevice(device.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device "${device.name}" revoked successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reload user details to get updated devices list
        context.read<UserManagementBloc>().add(
              UserManagementLoadByIdRequested(widget.user.id),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to revoke device: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRevoking = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Devices'),
      ),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          // Show updated devices if we just loaded the user
          List<Device>? currentDevices = widget.user.devices;
          if (state is UserManagementDetailLoaded) {
            currentDevices = state.user.devices;
          }

          if (currentDevices == null || currentDevices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No devices registered',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User has not registered any devices yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.smartphone,
                          size: 28,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentDevices.length} registered device${currentDevices.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Devices List
              Text(
                'Registered Devices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...currentDevices.map((device) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.phone_android,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.block),
                                color: Colors.red,
                                tooltip: 'Revoke device',
                                onPressed: _isRevoking
                                    ? null
                                    : () => _confirmRevokeDevice(device),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Device ID',
                            value: '#${device.id}',
                          ),
                          if (device.createdAt != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Registered',
                              value: _formatDate(device.createdAt!),
                            ),
                          ],
                          if (device.lastUsedAt != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Last Used',
                              value: _formatDate(device.lastUsedAt!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
            ],
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
