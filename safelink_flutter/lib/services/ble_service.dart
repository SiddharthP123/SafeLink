import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static const String _serviceUuid    = '12345678-1234-1234-1234-123456789012';
  static const String _buttonCharUuid = '87654321-4321-4321-4321-210987654321';
  static const String _motorCharUuid  = 'aaaabbbb-cccc-dddd-eeee-ffffffffffff';

  static BluetoothDevice? _device;
  static BluetoothCharacteristic? _motorChar;
  static StreamSubscription<List<ScanResult>>? _scanSub;
  static StreamSubscription<List<int>>? _notifySub;
  static StreamSubscription<BluetoothConnectionState>? _connSub;

  static int? _rssi;
  static Timer? _rssiTimer;
  static final StreamController<int?> _rssiCtrl =
      StreamController<int?>.broadcast();

  static bool get isConnected => _device != null;
  static int? get currentRssi => _rssi;
  static Stream<int?> get rssiStream => _rssiCtrl.stream;

  static Future<void> connect({
    required void Function(String type) onButtonPress,
    required VoidCallback onConnect,
    String bandName = 'SafeLink-A',
  }) async {
    await disconnect();
    debugPrint('[BLE] Scanning for $bandName...');

    final adapterState = await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => BluetoothAdapterState.unknown,
        );

    if (adapterState != BluetoothAdapterState.on) {
      debugPrint('[BLE] Bluetooth not available ($adapterState) — skipping scan');
      return;
    }

    await FlutterBluePlus.startScan();

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        if (name == bandName) {
          await FlutterBluePlus.stopScan();
          await _scanSub?.cancel();
          _scanSub = null;
          await _connectToDevice(result.device, onConnect, onButtonPress);
          return;
        }
      }
    });
  }

  static Future<void> _connectToDevice(
    BluetoothDevice device,
    VoidCallback onConnect,
    void Function(String) onButtonPress,
  ) async {
    _device = device;
    debugPrint('[BLE] Connecting to ${device.platformName}...');

    try {
      await device.connect(autoConnect: false, license: License.nonprofit);
    } catch (e) {
      debugPrint('[BLE] Connect error: $e');
      _device = null;
      return;
    }

    debugPrint('[BLE] Connected to ${device.platformName}');

    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint('[BLE] Band disconnected');
        _device = null;
        _motorChar = null;
        _rssiTimer?.cancel();
        _rssi = null;
        _rssiCtrl.add(null);
      }
    });

    final services = await device.discoverServices();
    for (final service in services) {
      if (service.serviceUuid.toString().toLowerCase() != _serviceUuid) continue;

      for (final char in service.characteristics) {
        final uuid = char.characteristicUuid.toString().toLowerCase();

        if (uuid == _buttonCharUuid) {
          await char.setNotifyValue(true);
          _notifySub = char.lastValueStream.listen((bytes) {
            if (bytes.isEmpty) return;
            final event = utf8.decode(bytes).trim();
            debugPrint('[BLE] Button event → $event');
            if (event == 'COMFORT' || event == 'SOS') onButtonPress(event);
          });
        }

        if (uuid == _motorCharUuid) _motorChar = char;
      }
    }

    onConnect();

    // Poll RSSI every 2 seconds while connected
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_device == null) return;
      try {
        final rssi = await _device!.readRssi();
        _rssi = rssi;
        _rssiCtrl.add(rssi);
      } catch (_) {}
    });
  }

  static Future<void> vibrate(String type) async {
    if (_motorChar == null) {
      debugPrint('[BLE] vibrate() — motor characteristic not available');
      return;
    }
    final command = type == 'SOS' ? 'SOS_VIBRATE' : 'VIBRATE';
    debugPrint('[BLE] Sending vibration command: $command');
    try {
      await _motorChar!.write(utf8.encode(command), withoutResponse: false);
    } catch (e) {
      debugPrint('[BLE] vibrate error: $e');
    }
  }

  static Future<void> disconnect() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    await _notifySub?.cancel();
    _notifySub = null;
    await _connSub?.cancel();
    _connSub = null;
    _rssiTimer?.cancel();
    _rssiTimer = null;
    _rssi = null;
    _rssiCtrl.add(null);

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
      _device = null;
    }
    _motorChar = null;
    debugPrint('[BLE] Disconnected');
  }
}
