import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pairing_service.dart';
import 'main_screen.dart';

class PairingCodeEntryScreen extends StatefulWidget {
  final String deviceName;

  const PairingCodeEntryScreen({
    super.key,
    required this.deviceName,
  });

  @override
  State<PairingCodeEntryScreen> createState() => _PairingCodeEntryScreenState();
}

class _PairingCodeEntryScreenState extends State<PairingCodeEntryScreen> {
  final _pairingService = PairingService();
  final _codeController = TextEditingController();
  bool _isPairing = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _completePairing() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(child: Text('Invalid code')),
        ),
      );
      return;
    }

    setState(() {
      _isPairing = true;
      _statusMessage = 'Pairing...';
    });

    try {
      await _pairingService.completePairing(
        code: code,
        deviceName: widget.deviceName,
      );

      setState(() {
        _statusMessage = 'Success!';
        _isPairing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Center(child: Text('Paired')),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      String errorMsg = 'Pairing failed';
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        errorMsg = 'Network error';
      } else if (errorStr.contains('code') ||
                 errorStr.contains('invalid') ||
                 errorStr.contains('expired')) {
        errorMsg = 'Invalid code';
      }

      setState(() {
        _statusMessage = errorMsg;
        _isPairing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text(errorMsg)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smartphone,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter the 6-digit code from your smartphone',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 20, letterSpacing: 6),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(),
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  enabled: !_isPairing,
                ),
                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isPairing ? null : _completePairing,
                  icon: _isPairing
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text(
                    'Pair',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
