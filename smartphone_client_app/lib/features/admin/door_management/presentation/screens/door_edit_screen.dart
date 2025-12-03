import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door.dart';
import 'package:smartphone_client_app/features/admin/door_management/data/models/door_update_request.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_bloc.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_event.dart';
import 'package:smartphone_client_app/features/admin/door_management/presentation/bloc/door_management_state.dart';

class DoorEditScreen extends StatefulWidget {
  final Door door;

  const DoorEditScreen({
    super.key,
    required this.door,
  });

  @override
  State<DoorEditScreen> createState() => _DoorEditScreenState();
}

class _DoorEditScreenState extends State<DoorEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _deviceIdController;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing door data
    _nameController = TextEditingController(text: widget.door.name);
    _latitudeController =
        TextEditingController(text: widget.door.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.door.longitude.toString());
    _locationController = TextEditingController(text: widget.door.location ?? '');
    _descriptionController =
        TextEditingController(text: widget.door.description ?? '');
    _deviceIdController = TextEditingController(text: widget.door.deviceId ?? '');
    _isActive = widget.door.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = DoorUpdateRequest(
        name: _nameController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        deviceId: _deviceIdController.text.trim().isEmpty
            ? null
            : _deviceIdController.text.trim(),
        isActive: _isActive,
      );

      context.read<DoorManagementBloc>().add(
            DoorManagementUpdateRequested(widget.door.id, request),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoorManagementBloc, DoorManagementState>(
      listener: (context, state) {
        if (state is DoorManagementOperationInProgress) {
          setState(() => _isSubmitting = true);
        } else if (state is DoorManagementOperationSuccess) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Return success
        } else if (state is DoorManagementError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Door')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
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
                          Icons.door_front_door,
                          size: 32,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Door',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Update door information',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Door Name *',
                  hintText: 'e.g., Main Lab Entrance',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Door name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Door name must be at least 3 characters';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),

              // Location Field (optional)
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Building A, Floor 2',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.words,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),

              // GPS Coordinates Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'GPS Coordinates *',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Latitude
                      TextFormField(
                        controller: _latitudeController,
                        decoration: InputDecoration(
                          labelText: 'Latitude *',
                          hintText: 'e.g., 40.631467',
                          prefixIcon: const Icon(Icons.straighten),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Latitude is required';
                          }
                          final lat = double.tryParse(value.trim());
                          if (lat == null) {
                            return 'Enter a valid number';
                          }
                          if (lat < -90 || lat > 90) {
                            return 'Latitude must be between -90 and 90';
                          }
                          return null;
                        },
                        enabled: !_isSubmitting,
                      ),
                      const SizedBox(height: 16),
                      // Longitude
                      TextFormField(
                        controller: _longitudeController,
                        decoration: InputDecoration(
                          labelText: 'Longitude *',
                          hintText: 'e.g., -8.659510',
                          prefixIcon: const Icon(Icons.straighten),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Longitude is required';
                          }
                          final lon = double.tryParse(value.trim());
                          if (lon == null) {
                            return 'Enter a valid number';
                          }
                          if (lon < -180 || lon > 180) {
                            return 'Longitude must be between -180 and 180';
                          }
                          return null;
                        },
                        enabled: !_isSubmitting,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Device ID (BLE MAC address)
              TextFormField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  labelText: 'Device ID (BLE MAC) - Optional',
                  hintText: 'e.g., AA:BB:CC:DD:EE:FF',
                  prefixIcon: const Icon(Icons.bluetooth),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),

              // Description Field (optional)
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional details about this door...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 16),

              // Active Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Door is active and can be accessed',
                  ),
                  value: _isActive,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() => _isActive = value);
                        },
                  secondary: Icon(
                    _isActive ? Icons.check_circle : Icons.cancel,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
