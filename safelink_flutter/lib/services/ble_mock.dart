import 'dart:async';
import 'package:flutter/foundation.dart';

/// Mock BLE service that simulates an ESP32-C3 SafeLink wristband.
/// Used for testing the full app flow without real hardware.
///
/// Timeline after calling [connect]:
///   0 s  → logs "[MOCK BLE] Scanning..."
///   2 s  → logs "[MOCK BLE] Connected to SafeLink-A", calls onConnect
///   7 s  → calls onButtonPress('COMFORT')   (5 s after connect)
///  14 s  → calls onButtonPress('SOS')       (12 s after connect)
class BLEMock {
  static bool _isConnected = false;
  static final List<Timer> _timers = [];

  static bool get isConnected => _isConnected;

  /// Start the mock BLE session.
  /// [onButtonPress] is called with 'COMFORT' or 'SOS' when a simulated
  /// button event fires.
  /// [onConnect] is called once the mock connection is established (2 s).
  static void connect({
    required void Function(String type) onButtonPress,
    required VoidCallback onConnect,
  }) {
    // Cancel any previous session before starting a new one.
    disconnect();

    debugPrint('[MOCK BLE] Scanning...');

    // Simulate 2-second connection delay.
    _timers.add(Timer(const Duration(seconds: 2), () {
      _isConnected = true;
      debugPrint('[MOCK BLE] Connected to SafeLink-A');
      onConnect();

      // Auto-fire COMFORT 5 seconds after connect (7 s total).
      _timers.add(Timer(const Duration(seconds: 5), () {
        debugPrint('[MOCK BLE] Button event → COMFORT');
        onButtonPress('COMFORT');
      }));

      // Auto-fire SOS 12 seconds after connect (14 s total).
      _timers.add(Timer(const Duration(seconds: 12), () {
        debugPrint('[MOCK BLE] Button event → SOS');
        onButtonPress('SOS');
      }));
    }));
  }

  /// Simulate sending a vibration command to the band.
  /// In real hardware this would write to MOTOR_CHAR_UUID.
  static void vibrate(String type) {
    debugPrint('[MOCK BLE] Vibrating — $type');
  }

  /// Cancel all pending timers and mark as disconnected.
  static void disconnect() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _isConnected = false;
    debugPrint('[MOCK BLE] Disconnected');
  }
}
