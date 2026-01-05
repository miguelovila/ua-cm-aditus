import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoveredDoor {
  final String deviceId;
  final String name;
  final int rssi;
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

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;

  BleService._internal() {
    FlutterBluePlus.scanResults.listen((results) {
      if (_isScanning) {
        _discoveredDoors.clear();
        for (final result in results) {
          final door = DiscoveredDoor.fromScanResult(result);
          _discoveredDoors[door.deviceId] = door;
        }
        _scanResultsController.add(_discoveredDoors.values.toList());
      }
    });
  }

  static const String doorServiceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String challengeUuid = '6a3d9e2c-2a9a-4c1b-8f0a-7b8b5a3d0b1a';
  static const String statusUuid = '8f0a7b8b-5a3d-4c1b-8f0a-6f3d9e2c2a9a';
  static const String idUuid = '5f2e6f9a-6f3d-4a1b-8f0a-7b8b5a3d0b1a';
  static const String signatureUuid = '7b8b5a3d-0b1a-4c1b-8f0a-6f3d9e2c2a9a';

  final _scanResultsController =
      StreamController<List<DiscoveredDoor>>.broadcast();
  final _scanStateController = StreamController<bool>.broadcast();
  final Map<String, DiscoveredDoor> _discoveredDoors = {};
  final Map<String, StreamController<String>> _characteristicStreams = {};

  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _discoveredServices;

  Stream<List<DiscoveredDoor>> get scanResults => _scanResultsController.stream;
  Stream<bool> get scanState => _scanStateController.stream;

  Future<void> startScan() async {
    if (_isScanning) return;

    _discoveredDoors.clear();
    _isScanning = true;
    _scanStateController.add(true);

    try {
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported');
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is off');
      }

      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          throw Exception('Location permission required');
        }
      }

      await FlutterBluePlus.startScan(
        withServices: [Guid(doorServiceUuid)],
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: true,
        continuousDivisor: 1,
      );
    } catch (e) {
      _isScanning = false;
      _scanStateController.add(false);
      rethrow;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _scanStateController.add(false);
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      final scanResults = await FlutterBluePlus.scanResults.first;
      final result = scanResults.firstWhere(
        (r) => r.device.remoteId.toString() == deviceId,
        orElse: () => throw Exception('Device not found in scan results'),
      );

      _connectedDevice = result.device;

      await _connectedDevice!.connect(
        license: License.free,
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<void> discoverServices(String deviceId) async {
    if (_connectedDevice == null) {
      throw Exception('Not connected to device');
    }

    try {
      _discoveredServices = await _connectedDevice!.discoverServices();

      final doorService = _discoveredServices!.firstWhere(
        (s) => s.uuid.toString() == doorServiceUuid,
        orElse: () => throw Exception('Door service not found'),
      );

      final requiredChars = [challengeUuid, statusUuid, idUuid, signatureUuid];
      for (final uuid in requiredChars) {
        doorService.characteristics.firstWhere(
          (c) => c.uuid.toString() == uuid,
          orElse: () => throw Exception('Required characteristic $uuid not found'),
        );
      }
    } catch (e) {
      throw Exception('Service discovery failed: $e');
    }
  }

  Future<Stream<String>> listenToCharacteristic(String characteristicUuid) async {
    if (_discoveredServices == null) {
      throw Exception('Services not discovered');
    }

    if (!_characteristicStreams.containsKey(characteristicUuid)) {
      _characteristicStreams[characteristicUuid] =
          StreamController<String>.broadcast();

      final doorService = _discoveredServices!.firstWhere(
        (s) => s.uuid.toString() == doorServiceUuid,
      );

      final characteristic = doorService.characteristics.firstWhere(
        (c) => c.uuid.toString() == characteristicUuid,
        orElse: () =>
            throw Exception('Characteristic $characteristicUuid not found'),
      );

      characteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            final stringValue = utf8.decode(value);
            _characteristicStreams[characteristicUuid]?.add(stringValue);
          }
        },
        onError: (error) {
          _characteristicStreams[characteristicUuid]?.addError(error);
        },
      );

      await characteristic.setNotifyValue(true);
    }

    return _characteristicStreams[characteristicUuid]!.stream;
  }

  Future<void> writeToCharacteristic(
    String characteristicUuid,
    String value, {
    bool allowLongWrite = false,
  }) async {
    if (_discoveredServices == null) {
      throw Exception('Services not discovered');
    }

    final doorService = _discoveredServices!.firstWhere(
      (s) => s.uuid.toString() == doorServiceUuid,
    );

    final characteristic = doorService.characteristics.firstWhere(
      (c) => c.uuid.toString() == characteristicUuid,
      orElse: () => throw Exception('Characteristic $characteristicUuid not found'),
    );

    final bytes = utf8.encode(value);
    await characteristic.write(
      bytes,
      withoutResponse: false,
      allowLongWrite: allowLongWrite,
    );
  }

  Future<void> disconnectFromDevice() async {
    try {
      for (final controller in _characteristicStreams.values) {
        await controller.close();
      }
      _characteristicStreams.clear();
      _discoveredServices = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }
    } catch (e) {
    }
  }

  void dispose() {
    _scanResultsController.close();
    _scanStateController.close();
    for (final controller in _characteristicStreams.values) {
      controller.close();
    }
  }
}
