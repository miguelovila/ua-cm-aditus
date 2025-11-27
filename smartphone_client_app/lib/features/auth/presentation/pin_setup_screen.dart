import 'package:flutter/material.dart';
import 'package:smartphone_client_app/core/security/pin_service.dart';
import 'package:smartphone_client_app/core/security/biometric_service.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';
import 'package:smartphone_client_app/features/device/presentation/device_registration_screen.dart';
import 'package:smartphone_client_app/screens/home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinService = PinService();
  final _biometricService = BiometricService();

  bool _enableBiometrics = false;
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _biometricsAvailable = false;
  String? _errorMessage;
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isSupported = await _biometricService.isDeviceSupported();
    final biometrics = await _biometricService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _biometricsAvailable = canCheck && isSupported && biometrics.isNotEmpty;
      });

      if (_biometricsAvailable) {
        final typeName = await _biometricService.getBiometricTypeName();
        setState(() {
          _biometricTypeName = typeName;
        });
      }
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (!value) {
      setState(() {
        _enableBiometrics = false;
      });
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to enable $_biometricTypeName',
    );

    if (authenticated) {
      setState(() {
        _enableBiometrics = true;
      });
    } else {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Biometric authentication failed',
        );
      }
    }
  }

  Future<void> _handleSetup() async {
    setState(() {
      _errorMessage = null;
    });

    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _pinService.setupPin(_pinController.text);

      if (_enableBiometrics && _biometricsAvailable) {
        await _biometricService.setBiometricEnabled(true);
      } else {
        await _biometricService.setBiometricEnabled(false);
      }

      if (!mounted) return;

      SnackbarHelper.showSuccess(context, 'Security setup complete!');

      setState(() {
        _isLoading = false;
      });

      // Check if device is already registered (forgot PIN scenario)
      final storage = SecureStorageService();
      final deviceId = await storage.getDeviceId();

      if (!mounted) return;

      if (deviceId != null) {
        // Device already registered, go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // New user, continue to device registration
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DeviceRegistrationScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      SnackbarHelper.showError(context, 'Failed to setup security: $e');
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 90,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Secure Your Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a PIN to protect your account and sensitive actions',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter PIN',
                    hintText: 'Enter 4-6 digits',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                    ),
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscureConfirmPin,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  maxLength: 6,
                  onFieldSubmitted: (_) => _handleSetup(),
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    hintText: 'Re-enter your PIN',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPin
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPin = !_obscureConfirmPin;
                        });
                      },
                    ),
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (_biometricsAvailable)
                  Card(
                    child: SwitchListTile(
                      title: Text('Enable $_biometricTypeName'),
                      subtitle: Text('Use $_biometricTypeName for quick access'),
                      secondary: const Icon(Icons.fingerprint),
                      value: _enableBiometrics,
                      onChanged: _isLoading ? null : _handleBiometricToggle,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Biometric authentication is not available on this device',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _handleSetup,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isLoading ? 'Setting up...' : 'Complete Setup'),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your PIN is stored securely and will be required when performing sensitive actions like unlocking doors.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
