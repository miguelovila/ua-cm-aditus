import 'package:flutter/material.dart';
import 'package:smartphone_client_app/core/security/pin_service.dart';
import 'package:smartphone_client_app/core/ui/snackbar_helper.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinService = PinService();

  bool _isLoading = false;
  bool _obscureOldPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePin() async {
    setState(() {
      _errorMessage = null;
    });

    // Validate inputs
    if (_oldPinController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your current PIN';
      });
      return;
    }

    if (_newPinController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a new PIN';
      });
      return;
    }

    if (_newPinController.text == _oldPinController.text) {
      setState(() {
        _errorMessage = 'New PIN must be different from current PIN';
      });
      return;
    }

    if (_newPinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'New PINs do not match';
      });
      return;
    }

    // Validate PIN format (4-6 digits)
    final pinRegex = RegExp(r'^\d{4,6}$');
    if (!pinRegex.hasMatch(_newPinController.text)) {
      setState(() {
        _errorMessage = 'PIN must be 4-6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _pinService.changePin(
        _oldPinController.text,
        _newPinController.text,
      );

      if (!mounted) return;

      if (success) {
        SnackbarHelper.showSuccess(context, 'PIN changed successfully');
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Current PIN is incorrect';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      SnackbarHelper.showError(context, 'Failed to change PIN: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.pin_outlined, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Update Your PIN',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current PIN and choose a new one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Current PIN
              TextFormField(
                controller: _oldPinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureOldPin,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  hintText: 'Enter current PIN',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPin = !_obscureOldPin;
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

              const SizedBox(height: 24),

              // New PIN
              TextFormField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureNewPin,
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'New PIN',
                  hintText: 'Enter 4-6 digits',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPin = !_obscureNewPin;
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

              // Confirm New PIN
              TextFormField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirmPin,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                maxLength: 6,
                onFieldSubmitted: (_) => _handleChangePin(),
                decoration: InputDecoration(
                  labelText: 'Confirm New PIN',
                  hintText: 'Re-enter new PIN',
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
                    borderRadius: BorderRadius.circular(12),
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Change PIN Button
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _handleChangePin,
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
                  label: Text(_isLoading ? 'Changing PIN...' : 'Change PIN'),
                ),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your new PIN will be required for sensitive actions like unlocking doors.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
