import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'pairing_code_entry_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String _deviceName = 'this device';

  @override
  void initState() {
    super.initState();
    _getDeviceName();
  }

  Future<void> _getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (mounted) {
      setState(() {
        _deviceName = androidInfo.name;
      });
    }
  }

  void _startPairing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PairingCodeEntryScreen(
          deviceName: _deviceName,
        ),
      ),
    );
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
                  Icons.watch,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'To register your $_deviceName, tap "Start Pairing" and enter the code from your smartphone',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _startPairing,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text(
                    'Start Pairing',
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
