import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';
import '../../home/presentation/screens/home_screen.dart';
import 'bloc/bloc.dart';

class DeviceRegistrationScreen extends StatelessWidget {
  const DeviceRegistrationScreen({super.key});

  String _getDefaultDeviceName() {
    try {
      if (Platform.isAndroid) {
        return 'My Android Device';
      }
    } catch (_) {
      // If Platform check fails, use generic name
    }
    return 'My Device';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceBloc(),
      child: _DeviceRegistrationForm(
        defaultDeviceName: _getDefaultDeviceName(),
      ),
    );
  }
}

class _DeviceRegistrationForm extends StatefulWidget {
  final String defaultDeviceName;

  const _DeviceRegistrationForm({required this.defaultDeviceName});

  @override
  State<_DeviceRegistrationForm> createState() =>
      _DeviceRegistrationFormState();
}

class _DeviceRegistrationFormState extends State<_DeviceRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(
      text: widget.defaultDeviceName,
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      context.read<DeviceBloc>().add(
        DeviceRegisterRequested(_deviceNameController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<DeviceBloc, DeviceState>(
          listener: (context, state) {
            if (state is DeviceRegistered) {
              SnackbarHelper.showSuccess(
                context,
                'Device registered successfully!',
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else if (state is DeviceRegistrationError) {
              SnackbarHelper.showError(
                context,
                'Registration failed: ${state.message.replaceAll('Exception: ', '')}',
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is DeviceRegistering;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 90,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Register This Device',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Give your device a name and generate security keys',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      TextFormField(
                        controller: _deviceNameController,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Device Name',
                          hintText: 'e.g., My Android Phone',
                          prefixIcon: Icon(Icons.devices),
                          helperText: 'Choose a name to identify this device',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a device name';
                          }
                          if (value.length < 3) {
                            return 'Device name must be at least 3 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleRegistration(),
                      ),
                      const SizedBox(height: 32),

                      // Key generation info / Security info container
                      SizedBox(
                        height: 120,
                        child: isLoading
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Generating RSA-2048 security keys...',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.security,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'A unique cryptographic key pair will be generated for this device. Your private key never leaves your device.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: isLoading ? null : _handleRegistration,
                          icon: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.app_registration),
                          label: Text(
                            isLoading ? 'Registering...' : 'Register Device',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'What happens next?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _InfoItem(
                                icon: Icons.key,
                                text: 'RSA-2048 key pair generated locally',
                              ),
                              const SizedBox(height: 8),
                              _InfoItem(
                                icon: Icons.lock,
                                text: 'Private key stored securely on device',
                              ),
                              const SizedBox(height: 8),
                              _InfoItem(
                                icon: Icons.cloud_upload,
                                text:
                                    'Public key sent to server for verification',
                              ),
                              const SizedBox(height: 8),
                              _InfoItem(
                                icon: Icons.check_circle,
                                text: 'Device ready to unlock doors',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
