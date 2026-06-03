import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static const _storage = FlutterSecureStorage();
  static const _comfortKey = 'pref_comfort_alerts';

  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Initialise (call once in main()) ─────────────────────────────────────

  static Future<void> initialize() async {
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const settings = InitializationSettings(iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  static Future<void> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ── Show alert notification ───────────────────────────────────────────────

  static Future<void> showAlert({
    required String type,
    required double lat,
    required double lng,
  }) async {
    final isSOS = type == 'SOS';
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );
    await _plugin.show(
      isSOS ? 911 : 42,
      isSOS ? '🆘 SOS ALERT' : '🟡 Comfort Check-in',
      isSOS
          ? 'Your paired user needs urgent help! Open the app to view their location.'
          : 'Your paired user sent a comfort check-in. Open the app to view.',
      const NotificationDetails(iOS: iosDetails),
    );
  }

  // ── Comfort alert preference ──────────────────────────────────────────────

  static Future<bool> comfortAlertsEnabled() async {
    final v = await _storage.read(key: _comfortKey);
    return v != 'false';
  }

  static Future<void> setComfortAlerts(bool enabled) async {
    await _storage.write(key: _comfortKey, value: enabled ? 'true' : 'false');
  }

  // ── Band preference ───────────────────────────────────────────────────────

  static const _bandKey = 'pref_band_name';

  // Actual BLE advertisement names from the firmware
  static const bandAName = 'SafeLink-A'; // hyphen
  static const bandBName = 'SafeLink_B'; // underscore

  static Future<String> getBandName() async {
    final v = await _storage.read(key: _bandKey);
    return v ?? bandAName;
  }

  static Future<void> setBandName(String name) async {
    await _storage.write(key: _bandKey, value: name);
  }
}
