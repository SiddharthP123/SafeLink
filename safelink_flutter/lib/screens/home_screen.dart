import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ble_mock.dart';
import '../services/firebase_service.dart';
import '../services/contacts_service.dart';
import '../widgets/alert_banner.dart';
import '../widgets/status_dot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bleConnected = false;
  Map<String, dynamic>? _activeAlert;
  StreamSubscription<Map<String, dynamic>?>? _alertSub;

  @override
  void initState() {
    super.initState();
    _startBLE();
    _listenForAlerts();
  }

  void _startBLE() {
    BLEMock.connect(
      onConnect: () {
        if (mounted) setState(() => _bleConnected = true);
      },
      onButtonPress: (String type) async {
        // When the (mock) button fires, send the alert to Firestore so the
        // second phone (or Firebase console) also receives it.
        debugPrint('[HomeScreen] BLE button press: $type');
        BLEMock.vibrate(type);
      },
    );
  }

  void _listenForAlerts() {
    _alertSub = FirebaseService.alertStream().listen((alert) {
      if (!mounted) return;
      if (alert == null || alert['seen'] == true) {
        setState(() => _activeAlert = null);
        return;
      }
      setState(() => _activeAlert = alert);

      // For SOS: attempt to launch SMS to all emergency contacts.
      if (alert['type'] == 'SOS') {
        _sendSOSSms(alert['lat'] as double, alert['lng'] as double);
      }

      // Trigger vibration command (mock).
      BLEMock.vibrate(alert['type'] as String);
    });
  }

  Future<void> _sendSOSSms(double lat, double lng) async {
    final contacts = await ContactsService.getContacts();
    if (contacts.isEmpty) return;

    final body = Uri.encodeComponent(
      'SOS ALERT from SafeLink!\n'
      'Location: https://maps.google.com/?q=$lat,$lng',
    );

    for (final contact in contacts) {
      final phone = contact['phone'] ?? '';
      if (phone.isEmpty) continue;
      final uri = Uri.parse('sms:$phone?body=$body');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _dismissAlert() async {
    await FirebaseService.markSeen();
    if (mounted) setState(() => _activeAlert = null);
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    BLEMock.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAlert =
        _activeAlert != null && _activeAlert!['seen'] != true;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SafeLink',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Safety wristband companion',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      StatusDot(connected: _bleConnected),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Connection card
                  _ConnectionCard(connected: _bleConnected),
                  const SizedBox(height: 24),

                  // Alert history placeholder
                  _SectionHeader(title: 'Status'),
                  const SizedBox(height: 12),
                  _StatusCard(
                    bleConnected: _bleConnected,
                    hasAlert: hasAlert,
                    alertType: _activeAlert?['type'] as String?,
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  _InfoCard(),
                ],
              ),
            ),

            // Alert banner overlay (slides in from top when alert active)
            if (hasAlert)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AlertBanner(
                  type: _activeAlert!['type'] as String,
                  lat: _activeAlert!['lat'] as double,
                  lng: _activeAlert!['lng'] as double,
                  onDismiss: _dismissAlert,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final bool connected;
  const _ConnectionCard({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? const Color(0xFF1D9E75)
        : const Color(0xFF534AB7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.watch_rounded : Icons.watch_off_rounded,
            color: color,
            size: 36,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                connected ? 'SafeLink-A' : 'No band paired',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                connected ? 'BLE connected (mock)' : 'Scanning via BLE...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: color.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool bleConnected;
  final bool hasAlert;
  final String? alertType;

  const _StatusCard({
    required this.bleConnected,
    required this.hasAlert,
    required this.alertType,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    Color color;
    IconData icon;

    if (hasAlert && alertType == 'SOS') {
      message = 'SOS alert active — check banner above';
      color = const Color(0xFFE24B4A);
      icon = Icons.warning_rounded;
    } else if (hasAlert && alertType == 'COMFORT') {
      message = 'Comfort alert received';
      color = const Color(0xFFBA7517);
      icon = Icons.favorite_rounded;
    } else if (bleConnected) {
      message = 'Band connected — monitoring for alerts';
      color = const Color(0xFF1D9E75);
      icon = Icons.check_circle_rounded;
    } else {
      message = 'Waiting for band connection...';
      color = Colors.grey;
      icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Short press → COMFORT alert (amber)\n'
            '• Long press → SOS alert (red) + SMS to contacts\n'
            '• Both users see alerts via Firestore in real time\n'
            '• Hardware arrives soon — mock mode is active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
