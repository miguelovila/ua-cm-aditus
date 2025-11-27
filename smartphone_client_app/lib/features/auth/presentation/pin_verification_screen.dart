import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartphone_client_app/core/security/pin_service.dart';
import 'package:smartphone_client_app/core/security/biometric_service.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';
import 'package:smartphone_client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smartphone_client_app/screens/home_screen.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final _pinController = TextEditingController();
  final _pinService = PinService();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePin = true;
  bool _biometricsAvailable = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _attemptBiometricAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isEnabled = await _biometricService.isBiometricEnabled();
    final canCheck = await _biometricService.canCheckBiometrics();

    if (mounted) {
      setState(() {
        _biometricsAvailable = isEnabled && canCheck;
      });
    }
  }

  Future<void> _attemptBiometricAuth() async {
    if (!_biometricsAvailable) return;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to access Aditus',
    );

    if (authenticated && mounted) {
      _navigateToHome();
    }
  }

  Future<void> _handlePinVerification() async {
    if (_pinController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your PIN';
      });
      return;
    }

    if (_failedAttempts >= _maxAttempts) {
      _handleForgotPin();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _pinService.verifyPin(_pinController.text);

      if (!mounted) return;

      if (isValid) {
        setState(() {
          _isLoading = false;
          _failedAttempts = 0;
        });
        _navigateToHome();
      } else {
        setState(() {
          _isLoading = false;
          _failedAttempts++;
          _errorMessage = 'Incorrect PIN. ${_maxAttempts - _failedAttempts} attempts remaining.';
          _pinController.clear();
        });

        if (_failedAttempts >= _maxAttempts) {
          SnackbarHelper.showError(
            context,
            'Too many failed attempts. Please log in again.',
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            _handleForgotPin();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to verify PIN: $e';
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _handleForgotPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'To reset your PIN, you will need to log in again and set up a new PIN. Your registered device will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthForgotPinRequested());
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
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
                    Icons.lock_person,
                    size: 90,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN to continue',
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
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    maxLength: 6,
                    autofocus: !_biometricsAvailable,
                    onFieldSubmitted: (_) => _handlePinVerification(),
                    decoration: InputDecoration(
                      labelText: 'Enter PIN',
                      hintText: 'Enter your PIN',
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
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handlePinVerification,
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
                      label: Text(_isLoading ? 'Verifying...' : 'Unlock'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_biometricsAvailable)
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _attemptBiometricAuth,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use Biometric'),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _handleForgotPin,
                    child: const Text('Forgot PIN?'),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
