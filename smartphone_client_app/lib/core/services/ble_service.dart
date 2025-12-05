import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal() {
    // Set up persistent subscription to scan results
    // This will receive continuous updates while scanning is active
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (_isScanning) {
        _log('Scan results: ${results.length} door(s) found');

        // Log discovered doors
        for (var result in results) {
          _log('  ${result.device.platformName.isEmpty ? "Unknown Door" : result.device.platformName} (${result.device.remoteId}) - RSSI: ${result.rssi} dBm');
        }

        _discoveredDoors = results
            .map((r) => DiscoveredDoor.fromScanResult(r))
            .toList();

        // Sort by RSSI (signal strength) - strongest first
        _discoveredDoors.sort((a, b) => b.rssi.compareTo(a.rssi));

        _scanResultsController.add(_discoveredDoors);
      }
    });
  }

  static const String doorServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  final _scanResultsController =
      StreamController<List<DiscoveredDoor>>.broadcast();
  final _scanStateController = StreamController<bool>.broadcast();

  Stream<List<DiscoveredDoor>> get scanResults => _scanResultsController.stream;
  Stream<bool> get scanState => _scanStateController.stream;

  List<DiscoveredDoor> _discoveredDoors = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  // Connection state
  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _discoveredServices;
  final Map<String, StreamController<String>> _characteristicStreams = {};

  Future<void> startScan() async {
    // Prevent multiple scans at once
    if (_isScanning) {
      _log('Scan already in progress');
      return;
    }

    _discoveredDoors.clear();
    _isScanning = true;
    _scanStateController.add(true);

    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported on this device');
      }

      // Check if Bluetooth is turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is turned off. Please enable Bluetooth.');
      }

      // Request location permissions (required for BLE scanning on Android)
      _log('Checking location permissions...');
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        _log('Requesting location permission...');
        final result = await Permission.location.request();
        if (!result.isGranted) {
          throw Exception(
              'Location permission is required for Bluetooth scanning. Please enable it in settings.');
        }
      }
      _log('Location permission granted');

      _log('Starting BLE scan with service UUID filter: $doorServiceUuid');

      // Scan with service UUID filter for door controllers
      // The persistent subscription in constructor will receive continuous updates
      // Use LOW_LATENCY mode for continuous RSSI updates (like nRF Connect)
      // No timeout - scans continuously until user manually stops
      await FlutterBluePlus.startScan(
        withServices: [Guid(doorServiceUuid)],
        androidScanMode: AndroidScanMode.lowLatency, // Continuous updates
        continuousUpdates: true, // Report duplicate advertisements
        continuousDivisor: 1, // Report every advertisement
      );
    } catch (e) {
      _log('Scan error: $e');
      _isScanning = false;
      _scanStateController.add(false);
      rethrow;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _scanStateController.add(false);
    _log('Scan stopped');
  }

  // Connection Management

  Future<void> connectToDevice(String deviceId) async {
    _log('Connecting to device: $deviceId');

    // Find device in scan results
    final scanResults = await FlutterBluePlus.scanResults.first;
    final result = scanResults.firstWhere(
      (r) => r.device.remoteId.toString() == deviceId,
      orElse: () => throw Exception('Device not found in scan results'),
    );

    _connectedDevice = result.device;

    // Connect with timeout
    await _connectedDevice!.connect(
      license: License.free, // Free license for educational/non-commercial use
      timeout: const Duration(seconds: 30),
    );
    _log('Connected to device');
  }

  Future<void> disconnectFromDevice() async {
    if (_connectedDevice != null) {
      _log('Disconnecting from device');
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _discoveredServices = null;

      // Close all characteristic streams
      for (final controller in _characteristicStreams.values) {
        await controller.close();
      }
      _characteristicStreams.clear();

      _log('Disconnected');
    }
  }

  // Service & Characteristic Discovery

  Future<void> discoverServices(String deviceId) async {
    if (_connectedDevice == null) {
      throw Exception('Device not connected');
    }

    _log('Discovering services...');
    _discoveredServices = await _connectedDevice!.discoverServices();
    _log('Services discovered: ${_discoveredServices?.length}');

    // Find the door service
    final doorService = _discoveredServices?.firstWhere(
      (s) => s.uuid.toString() == doorServiceUuid,
      orElse: () => throw Exception('Door service not found'),
    );

    _log('Door service found with ${doorService?.characteristics.length} characteristics');
  }

  // Characteristic Operations

  Future<void> writeToCharacteristic(
      String characteristicUuid, String value, {bool allowLongWrite = false}) async {
    if (_discoveredServices == null) {
      throw Exception('Services not discovered');
    }

    // Find the door service
    final doorService = _discoveredServices!.firstWhere(
      (s) => s.uuid.toString() == doorServiceUuid,
    );

    // Find the characteristic
    final characteristic = doorService.characteristics.firstWhere(
      (c) => c.uuid.toString() == characteristicUuid,
      orElse: () =>
          throw Exception('Characteristic $characteristicUuid not found'),
    );

    // Write value (UTF-8 encoded)
    final bytes = utf8.encode(value);
    _log('Writing ${bytes.length} bytes to characteristic $characteristicUuid (allowLongWrite: $allowLongWrite)');
    await characteristic.write(bytes, withoutResponse: false, allowLongWrite: allowLongWrite);
    _log('Written to characteristic $characteristicUuid successfully');
  }

  Future<Stream<String>> listenToCharacteristic(String characteristicUuid) async {
    _log('listenToCharacteristic called for $characteristicUuid');

    if (_discoveredServices == null) {
      throw Exception('Services not discovered');
    }

    // Create stream controller if not exists
    if (!_characteristicStreams.containsKey(characteristicUuid)) {
      _log('Creating new stream for $characteristicUuid');
      _characteristicStreams[characteristicUuid] =
          StreamController<String>.broadcast();

      // Find and subscribe to characteristic
      final doorService = _discoveredServices!.firstWhere(
        (s) => s.uuid.toString() == doorServiceUuid,
      );

      final characteristic = doorService.characteristics.firstWhere(
        (c) => c.uuid.toString() == characteristicUuid,
        orElse: () =>
            throw Exception('Characteristic $characteristicUuid not found'),
      );

      _log('Setting up notification listener for $characteristicUuid');

      // Listen to characteristic updates BEFORE enabling notifications
      characteristic.lastValueStream.listen(
        (value) {
          _log('lastValueStream emitted for $characteristicUuid: ${value.length} bytes');
          if (value.isNotEmpty) {
            final stringValue = utf8.decode(value);
            _log('Received from $characteristicUuid: $stringValue');
            _characteristicStreams[characteristicUuid]?.add(stringValue);
          } else {
            _log('Received empty value from $characteristicUuid');
          }
        },
        onError: (error) {
          _log('Error on $characteristicUuid stream: $error');
          _characteristicStreams[characteristicUuid]?.addError(error);
        },
        onDone: () {
          _log('Stream completed for $characteristicUuid');
        },
      );

      // Enable notifications and WAIT for it to complete
      _log('Enabling notifications for $characteristicUuid');
      await characteristic.setNotifyValue(true);
      _log('Notifications enabled for $characteristicUuid');
    } else {
      _log('Returning existing stream for $characteristicUuid');
    }

    return _characteristicStreams[characteristicUuid]!.stream;
  }

  void dispose() {
    _scanResultsSubscription?.cancel();
    _scanResultsController.close();
    _scanStateController.close();
    disconnectFromDevice();
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[BleService] $message');
    }
  }
}

class DiscoveredDoor {
  final String deviceId; // MAC address
  final String name; // Device name from BLE advertisement
  final int rssi; // Signal strength
  final DateTime discoveredAt;

  DiscoveredDoor({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.discoveredAt,
  });

  factory DiscoveredDoor.fromScanResult(ScanResult result) {
    return DiscoveredDoor(
      deviceId: result.device.remoteId.toString(),
      name: result.device.platformName.isNotEmpty
          ? result.device.platformName
          : 'Unknown Door',
      rssi: result.rssi,
      discoveredAt: DateTime.now(),
    );
  }
}
