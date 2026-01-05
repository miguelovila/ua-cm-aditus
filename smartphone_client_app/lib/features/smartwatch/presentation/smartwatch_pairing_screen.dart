import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/api/device_api_service.dart';

class SmartWatchPairingScreen extends StatefulWidget {
  const SmartWatchPairingScreen({super.key});

  @override
  State<SmartWatchPairingScreen> createState() => _SmartWatchPairingScreenState();
}

class _SmartWatchPairingScreenState extends State<SmartWatchPairingScreen> {
  final _deviceApiService = DeviceApiService();

  String _pairingCode = '';
  bool _isWaiting = false;
  String _statusMessage = '';
  Timer? _expiryTimer;
  int _remainingSeconds = 300;

  @override
  void initState() {
    super.initState();
    _generatePairingCode();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _generatePairingCode() async {
    setState(() {
      _statusMessage = 'Generating pairing code...';
    });

    try {
      final response = await _deviceApiService.initiateSmartwatchPairing();

      final code = response['code'] as String;
      final expiresAt = DateTime.parse(response['expires_at']);
      final remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds;

      setState(() {
        _pairingCode = code;
        _isWaiting = true;
        _statusMessage = 'Enter this code on your smartwatch';
        _remainingSeconds = remainingSeconds > 0 ? remainingSeconds : 300;
      });

      _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          setState(() {
            _isWaiting = false;
            _statusMessage = 'Code expired. Generate a new code.';
          });
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to generate code: $e';
        _isWaiting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _pairingCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Smartwatch'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.watch,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _pairingCode,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (_isWaiting) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Expires in $_formattedTime',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Code'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isWaiting ? null : _generatePairingCode,
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('1. Open the Aditus app on your smartwatch'),
                      const SizedBox(height: 8),
                      const Text('2. Tap "Start Pairing"'),
                      const SizedBox(height: 8),
                      const Text('3. Enter the code shown above'),
                      const SizedBox(height: 8),
                      const Text('4. Wait for confirmation'),
                    ],
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
