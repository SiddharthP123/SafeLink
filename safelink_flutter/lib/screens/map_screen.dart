import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import '../widgets/wave_background.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Map<String, dynamic>? _lastAlert;
  StreamSubscription<Map<String, dynamic>?>? _sub;
  final List<Map<String, dynamic>> _alertHistory = [];

  @override
  void initState() {
    super.initState();
    _sub = FirebaseService.alertStream().listen((alert) {
      if (!mounted) return;
      if (alert == null || alert['seen'] == true) {
        // Alert dismissed — clear active view, keep history
        setState(() => _lastAlert = null);
        return;
      }
      final ts = alert['timestamp'] as int? ?? 0;
      final isDuplicate = _alertHistory.isNotEmpty &&
          (_alertHistory.first['timestamp'] as int? ?? -1) == ts;
      if (!isDuplicate) {
        _alertHistory.insert(0, Map<String, dynamic>.from(alert));
        if (_alertHistory.length > 10) _alertHistory.removeLast();
      }
      setState(() => _lastAlert = alert);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
    }
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} · ${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg,
      body: SafeArea(
        child: _lastAlert == null ? _buildEmpty() : _buildAlert(_lastAlert!),
      ),
    );
  }

  Widget _buildEmpty() {
    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: WaveBackground())),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _screenHeader(),
              if (_alertHistory.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📍', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 20),
                        Text('NO ALERT\nYET.', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SL.white, height: 0.95, letterSpacing: -1)),
                        SizedBox(height: 12),
                        Text('When your paired user sends an alert,\ntheir location appears here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: SL.grey, height: 1.5)),
                      ],
                    ),
                  ),
                )
              else ...[
                const SizedBox(height: 20),
                const Text('RECENT ALERTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _alertHistory.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = _alertHistory[i];
                      final isSOS = (a['type'] as String?) == 'SOS';
                      final accent = isSOS ? SL.red : SL.yellow;
                      final lat = (a['lat'] as double?)?.toStringAsFixed(5) ?? '—';
                      final lng = (a['lng'] as double?)?.toStringAsFixed(5) ?? '—';
                      final ts = a['timestamp'] as int? ?? 0;
                      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
                      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} · ${dt.day}/${dt.month}';
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: SL.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: accent.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                              child: Text(a['type'] as String? ?? '?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent, letterSpacing: 1)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$lat, $lng', style: const TextStyle(fontSize: 11, color: SL.white, fontWeight: FontWeight.w600)),
                                  Text(time, style: const TextStyle(fontSize: 10, color: SL.grey)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openInGoogleMaps(a['lat'] as double, a['lng'] as double),
                              child: const Icon(Icons.open_in_new_rounded, color: SL.grey, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlert(Map<String, dynamic> alert) {
    final type   = alert['type'] as String;
    final lat    = alert['lat'] as double;
    final lng    = alert['lng'] as double;
    final ts     = alert['timestamp'] as int;
    final isSOS  = type == 'SOS';
    final accent = isSOS ? SL.red : SL.yellow;
    final centre = LatLng(lat, lng);

    return Stack(
      children: [
        // Background waves — red tones for SOS, amber tones for COMFORT
        Positioned.fill(child: IgnorePointer(child: WaveBackground(
          layerColors: isSOS ? WaveBackground.sosColors : WaveBackground.comfortColors,
        ))),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _screenHeader(accent: accent),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(100)),
                    child: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 10),
                  Text(isSOS ? 'SOS\nALERT' : 'COMFORT\nALERT',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: accent, height: 0.92, letterSpacing: -1.5)),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Embedded map
            Expanded(
              child: FlutterMap(
                key: ValueKey(ts),
                options: MapOptions(initialCenter: centre, initialZoom: 15.5),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.Siddharth.SafeLink'),
                  MarkerLayer(markers: [
                    Marker(
                      point: centre,
                      width: 50, height: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: accent.withAlpha(120), blurRadius: 12, spreadRadius: 2)],
                            ),
                            child: Icon(isSOS ? Icons.sos_rounded : Icons.favorite_rounded, color: SL.bg, size: 18),
                          ),
                          CustomPaint(size: const Size(2, 10), painter: _PinStem(accent)),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Info strip
            Container(
              color: SL.bg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _CoordChip(label: 'LAT', value: lat.toStringAsFixed(5))),
                      const SizedBox(width: 8),
                      Expanded(child: _CoordChip(label: 'LNG', value: lng.toStringAsFixed(5))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_formatTimestamp(ts), style: const TextStyle(fontSize: 11, color: SL.darkGrey)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openInGoogleMaps(lat, lng),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: SL.border)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded, color: SL.grey, size: 15),
                          SizedBox(width: 8),
                          Text('OPEN IN GOOGLE MAPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _screenHeader({Color? accent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 2)),
        const Text('MAP', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SL.white, height: 1, letterSpacing: -1)),
        const SizedBox(height: 14),
        const _FakeActivityBadge(),
      ],
    );
  }
}

// ── Fake activity badge ────────────────────────────────────────────────────

class _FakeActivityBadge extends StatefulWidget {
  const _FakeActivityBadge();

  @override
  State<_FakeActivityBadge> createState() => _FakeActivityBadgeState();
}

class _FakeActivityBadgeState extends State<_FakeActivityBadge> {
  int _users = 152;
  int _bars  = 3;
  Timer? _t;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _users = 146 + _rng.nextInt(20);
    _bars  = 2 + _rng.nextInt(2);
    _t = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (!mounted) return;
      setState(() {
        _users = (_users + _rng.nextInt(5) - 2).clamp(115, 185);
        _bars  = (_bars  + _rng.nextInt(3) - 1).clamp(1, 3);
      });
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  ({String label, Color color}) get _status {
    if (_users >= 168) return (label: 'BUSY',      color: SL.red);
    if (_users >= 148) return (label: 'ACTIVE',    color: SL.yellow);
    if (_users >= 128) return (label: 'MODERATE',  color: SL.lime);
    return               (label: 'QUIET',     color: SL.grey);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SL.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.color.withAlpha(80)),
      ),
      child: Row(
        children: [
          // Signal bars (larger)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) => Container(
              width: 6,
              height: 8.0 + i * 7.0,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: i < _bars ? s.color : SL.darkGrey,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_users users connected',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SL.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'SafeLink Network',
                  style: const TextStyle(fontSize: 10, color: SL.grey, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: s.color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.color.withAlpha(80)),
            ),
            child: Text(
              s.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.color, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _CoordChip extends StatelessWidget {
  final String label;
  final String value;
  const _CoordChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: SL.border)),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: SL.grey, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, color: SL.white, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}

class _PinStem extends CustomPainter {
  final Color color;
  const _PinStem(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), Paint()..color = color..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
