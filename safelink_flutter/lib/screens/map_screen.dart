import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';

/// Map screen — listens to Firestore alertStream and displays the last
/// received alert location. Avoids google_maps_flutter to prevent native
/// plugin friction during mock testing. Tapping "Open in Google Maps"
/// launches the system maps app via url_launcher.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Map<String, dynamic>? _lastAlert;
  StreamSubscription<Map<String, dynamic>?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseService.alertStream().listen((alert) {
      if (!mounted) return;
      if (alert != null && alert['seen'] != true) {
        setState(() => _lastAlert = alert);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps.')),
      );
    }
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')} '
        '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Map'),
        backgroundColor: const Color(0xFF534AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _lastAlert == null ? _buildEmpty() : _buildAlert(_lastAlert!),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '📍',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'No alert received yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When your paired user sends an alert,\ntheir location will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(Map<String, dynamic> alert) {
    final type = alert['type'] as String;
    final lat = alert['lat'] as double;
    final lng = alert['lng'] as double;
    final ts = alert['timestamp'] as int;
    final isSOS = type == 'SOS';

    final badgeColor =
        isSOS ? const Color(0xFFE24B4A) : const Color(0xFFBA7517);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Location card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withAlpha(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last Known Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _CoordRow(label: 'Latitude', value: lat.toStringAsFixed(6)),
                const SizedBox(height: 6),
                _CoordRow(label: 'Longitude', value: lng.toStringAsFixed(6)),
                const SizedBox(height: 6),
                _CoordRow(label: 'Received', value: _formatTimestamp(ts)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Placeholder map visual
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid lines background
                CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: _GridPainter(),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_pin,
                      size: 48,
                      color: badgeColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Open in Google Maps button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(lat, lng),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF534AB7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Draws a simple grid to hint at a map background.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
