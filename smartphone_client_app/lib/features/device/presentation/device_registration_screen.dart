import 'package:flutter/material.dart';
import 'package:smartphone_client_app/core/api/api_client.dart';
import 'package:smartphone_client_app/core/security/crypto_service.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';
import 'dart:io' show Platform;
import '../../../screens/home_screen.dart';

class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  bool _isLoading = false;
  bool _isGeneratingKeys = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with default device name
    _deviceNameController.text = _getDefaultDeviceName();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  String _getDefaultDeviceName() {
    try {
      // Get platform name
      if (Platform.isAndroid) {
        return 'My Android Device';
      }
    } catch (_) {
      // If Platform check fails, use generic name
    }
    return 'My Device';
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isGeneratingKeys = true;
    });

    try {
      final cryptoService = CryptoService();

      // artificial delay to show loading animation
      await Future.delayed(const Duration(seconds: 2));

      final keyData = await cryptoService.generateKeyPair();

      final publicKeyPEM = keyData['publicKeyPEM'] as String;

      if (!mounted) return;

      setState(() {
        _isGeneratingKeys = false;
      });

      final storage = SecureStorageService();
      final accessToken = await storage.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found. Please log in again.');
      }

      final apiClient = ApiClient();
      final response = await apiClient.registerDevice(
        deviceName: _deviceNameController.text,
        publicKey: publicKeyPEM,
        accessToken: accessToken,
      );

      // Extract device ID from nested response structure
      final deviceData = response['device'] as Map<String, dynamic>?;
      final deviceId = deviceData?['id'];

      if (deviceId == null) {
        throw Exception('Device registration failed: No device ID returned');
      }

      await storage.saveDeviceId(deviceId.toString());

      if (!mounted) return;

      SnackbarHelper.showSuccess(context, 'Device registered successfully!');

      setState(() {
        _isLoading = false;
      });

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isGeneratingKeys = false;
      });

      SnackbarHelper.showError(context, 'Registration failed: ${e.message}');
    } catch (e) {
      // Other errors (crypto failures, etc.)
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isGeneratingKeys = false;
      });

      SnackbarHelper.showError(context, 'An error occurred: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Icon(
                    Icons.phone_android,
                    size: 90,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Register This Device',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

                  // Device name field
                  TextFormField(
                    controller: _deviceNameController,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
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
                  ),
                  const SizedBox(height: 32),

                  // Key generation info / Security info container
                  SizedBox(
                    height: 120,
                    child: _isGeneratingKeys
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.5,
                              ),
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
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
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleRegistration,
                      icon: _isLoading
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
                        _isLoading ? 'Registering...' : 'Register Device',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info card
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            context,
                            Icons.key,
                            'RSA-2048 key pair generated locally',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            context,
                            Icons.lock,
                            'Private key stored securely on device',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            context,
                            Icons.cloud_upload,
                            'Public key sent to server for verification',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            context,
                            Icons.check_circle,
                            'Device ready to unlock doors',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
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
