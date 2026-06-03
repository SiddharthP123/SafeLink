import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/ble_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../widgets/wave_background.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<_LogEntry> _log = [];
  bool _busy = false;
  final ScrollController _scrollCtrl = ScrollController();

  void _appendLog(String message, {bool isError = false}) {
    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    setState(() => _log.insert(0, _LogEntry(timestamp: ts, message: message, isError: isError)));
  }

  Future<void> _simulate(String type) async {
    if (_busy) return;
    setState(() => _busy = true);
    _appendLog('[$type] Getting GPS location...');
    try {
      final pos = await LocationService.getCurrentLocation();
      _appendLog('[$type] GPS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
      _appendLog('[$type] Writing to Firestore...');
      await FirebaseService.sendAlert(type, pos.latitude, pos.longitude);
      _appendLog('[$type] Firestore alert sent.');
      if (type == 'SOS') {
        _appendLog('[SOS] Opening SMS to emergency contacts...');
        final sent = await SmsService.sendSosAlerts(lat: pos.latitude, lng: pos.longitude);
        if (sent) {
          _appendLog('[SOS] SMS compose sheet opened.');
        } else {
          _appendLog('[SOS] No contacts saved — add some in the Contacts tab first!', isError: true);
        }
      }
    } catch (e) {
      _appendLog('[$type] ERROR: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: WaveBackground())),
          SafeArea(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          children: [
            // Header
            const Text('SIMULATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 2)),
            const Text('DEBUG', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SL.white, height: 1, letterSpacing: -1)),
            const SizedBox(height: 24),

            // ── Buttons ──────────────────────────────────────────────────
            _SimButton(
              label: 'COMFORT',
              sublabel: 'Simulate short press',
              icon: Icons.favorite_rounded,
              color: SL.yellow,
              busy: _busy,
              onTap: () => _simulate('COMFORT'),
            ),
            const SizedBox(height: 12),
            _SimButton(
              label: 'SOS',
              sublabel: 'Simulate long press',
              icon: Icons.warning_rounded,
              color: SL.red,
              busy: _busy,
              onTap: () => _simulate('SOS'),
            ),
            const SizedBox(height: 12),
            _SimButton(
              label: 'TEST BAND MOTOR',
              sublabel: BLEService.isConnected ? 'Sends vibrate to connected band' : 'No band connected',
              icon: Icons.vibration_rounded,
              color: SL.cyan,
              busy: false,
              onTap: BLEService.isConnected
                  ? () {
                      BLEService.vibrate('COMFORT');
                      _appendLog('[TEST] Vibrate command sent to band.');
                    }
                  : null,
            ),
            if (_busy) ...[
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: SL.lime)),
                  SizedBox(width: 8),
                  Text('Working...', style: TextStyle(fontSize: 12, color: SL.lime, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── Action log ───────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: SL.border)),
                color: SL.surface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ACTION LOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
                    if (_log.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _log.clear()),
                        child: const Text('CLEAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.lime, letterSpacing: 1)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_log.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: SL.border)),
                child: const Text('Tap a button above to fire a simulated alert.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: SL.grey)),
              )
            else
              ...List.generate(_log.length, (i) {
                final e = _log[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.timestamp, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: SL.darkGrey)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: e.isError ? SL.red : SL.white))),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 32),

            // ── Hardware / BLE (moved from Settings) ─────────────────────
            _SectionLabel('HARDWARE / BLE'),
            const SizedBox(height: 12),
            _InfoTile(label: 'BLE mode', value: 'Real (hardware pending)'),
            _InfoTile(label: 'Service UUID', value: '12345678-...012'),
            _InfoTile(label: 'Button char', value: '87654321-...321'),
            _InfoTile(label: 'Motor char', value: 'AAAABBBB-...FFF'),
            const SizedBox(height: 28),

            // ── Firebase (moved from Settings) ───────────────────────────
            _SectionLabel('FIREBASE'),
            const SizedBox(height: 12),
            _InfoTile(label: 'Project', value: 'connect-0-app'),
            _InfoTile(label: 'Collection', value: 'alerts / active'),
            _InfoTile(label: 'Updates', value: 'Firestore snapshots'),
            const SizedBox(height: 28),

            // ── Colour system (moved from Settings) ──────────────────────
            _SectionLabel('COLOUR SYSTEM'),
            const SizedBox(height: 12),
            _ColorTile(label: 'Lime',           hex: '#C1FF1A', color: SL.lime),
            _ColorTile(label: 'Pink',           hex: '#FF2D9B', color: SL.pink),
            _ColorTile(label: 'Blue',           hex: '#2B6BFF', color: SL.blue),
            _ColorTile(label: 'SOS red',        hex: '#FF3B3B', color: SL.red),
            _ColorTile(label: 'Comfort yellow', hex: '#FFD60A', color: SL.yellow),
            const SizedBox(height: 20),
          ],
        )),
        ],
      ),
    );
  }
}

class _SimButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onTap;
  const _SimButton({required this.label, required this.sublabel, required this.icon, required this.color, required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (busy || onTap == null) ? null : onTap,
      child: AnimatedOpacity(
        opacity: (busy || onTap == null) ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: SL.bg, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                  Text(sublabel, style: const TextStyle(fontSize: 12, color: SL.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5));
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: SL.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SL.white))),
        ],
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  final String label;
  final String hex;
  final Color color;
  const _ColorTile({required this.label, required this.hex, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: SL.white)),
          const Spacer(),
          Text(hex, style: const TextStyle(fontSize: 12, color: SL.grey, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String timestamp;
  final String message;
  final bool isError;
  const _LogEntry({required this.timestamp, required this.message, this.isError = false});
}
