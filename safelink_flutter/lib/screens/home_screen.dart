import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../app_theme.dart';
import '../services/ble_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';
import '../widgets/wave_background.dart';
import 'profile_screen.dart';

// ── Ring style enum ────────────────────────────────────────────────────────

enum RingStyle { beads, discs, stars, diamonds, hollow }

// ── Screen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bleConnected = false;
  String _firstName = '';
  Uint8List? _profilePhoto;
  StreamSubscription<int?>? _rssiSub;

  // Ring customisation state
  Color _ringColor = SL.lime;
  RingStyle _ringStyle = RingStyle.beads;

  @override
  void initState() {
    super.initState();
    _startBLE();
    _loadProfile();
    _rssiSub = BLEService.rssiStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadProfile() async {
    final name = await ProfileService.getFirstName();
    final photo = await ProfileService.getProfilePhotoBytes();
    if (mounted) setState(() { _firstName = name; _profilePhoto = photo; });
  }

  Future<void> _startBLE() async {
    final bandName = await NotificationService.getBandName();
    BLEService.connect(
      bandName: bandName,
      onConnect: () {
        if (mounted) setState(() => _bleConnected = true);
      },
      onButtonPress: (String type) async {
        debugPrint('[HomeScreen] BLE button press: $type');
        BLEService.vibrate(type);
        try {
          final position = await LocationService.getCurrentLocation();
          await FirebaseService.sendAlert(type, position.latitude, position.longitude);
          if (type == 'SOS') {
            await SmsService.sendSosAlerts(lat: position.latitude, lng: position.longitude);
          }
        } catch (e) {
          debugPrint('[HomeScreen] Failed to send alert: $e');
        }
      },
    );
  }

  @override
  void dispose() {
    _rssiSub?.cancel();
    BLEService.disconnect();
    super.dispose();
  }

  String get _greeting {
    if (_firstName.isNotEmpty) return 'HEY,\n${_firstName.toUpperCase()}.';
    final name = AuthService.currentUser?.displayName;
    if (name != null && name.isNotEmpty) {
      return 'HEY,\n${name.split(' ').first.toUpperCase()}.';
    }
    final hour = DateTime.now().hour;
    return hour < 12 ? 'GOOD\nMORNING.' : hour < 18 ? 'HEY\nTHERE.' : 'GOOD\nEVENING.';
  }

  void _openProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()))
        .then((_) => _loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = kReleaseMode ? 'v1.2' : (_bleConnected ? 'BLE v1.2' : 'TEST v1.2');

    return Scaffold(
      backgroundColor: SL.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: WaveBackground())),
          SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo pill with shield icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(100)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, size: 11, color: SL.bg),
                        SizedBox(width: 5),
                        Text('SAFELINK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // BLE dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: _bleConnected ? SL.lime : SL.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Mode / version label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: SL.elevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: SL.border),
                        ),
                        child: Text(modeLabel, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1)),
                      ),
                      const SizedBox(width: 10),
                      // Profile button (40×40, shows photo or initial)
                      GestureDetector(
                        onTap: _openProfile,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _profilePhoto == null ? SL.lime : null,
                            borderRadius: BorderRadius.circular(12),
                            border: _profilePhoto != null ? Border.all(color: SL.border) : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _profilePhoto != null
                              ? Image.memory(_profilePhoto!, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: SL.bg),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Greeting — multicolor gradient ──────────────────────────
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [SL.orange, SL.pink, SL.cyan, SL.purple],
                  stops: [0.0, 0.33, 0.66, 1.0],
                ).createShader(bounds),
                child: Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.92,
                    letterSpacing: -2,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Connection card ──────────────────────────────────────────
              _ConnectionCard(connected: _bleConnected),
              const SizedBox(height: 16),

              // ── Stat row: BLE STATUS + BAND STRENGTH ────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'BLE STATUS',
                      value: _bleConnected ? 'LIVE' : 'IDLE',
                      accent: _bleConnected ? SL.lime : SL.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SL.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BAND STRENGTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 22,
                            child: _bleConnected
                                ? _SignalBars(rssi: BLEService.currentRssi)
                                : const Text('—', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: SL.darkGrey)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── About SafeLink card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: SL.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: SL.lime.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.shield_rounded, color: SL.lime, size: 15),
                        ),
                        const SizedBox(width: 10),
                        const Text('ABOUT SAFELINK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _AboutRow(text: 'Safety tool for university students.'),
                    const SizedBox(height: 8),
                    const _AboutRow(text: 'Receive COMFORT & SOS alerts from your paired user.'),
                    const SizedBox(height: 8),
                    const _AboutRow(text: 'View live location in the Map tab when an alert fires.'),
                    const SizedBox(height: 8),
                    const _AboutRow(text: 'Long press your band → SOS sent to emergency contacts.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Fidget ring card ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: SL.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _firstName.isNotEmpty
                                ? "${_firstName.toUpperCase()}'S FIDGET RING"
                                : 'PERSONALIZED FIDGET RING',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text('DRAG · TAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SL.darkGrey, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Ring widget
                    _SpinRingWidget(color: _ringColor, style: _ringStyle),
                    const SizedBox(height: 18),
                    // Color options
                    _RingColorRow(
                      current: _ringColor,
                      onColor: (c) => setState(() => _ringColor = c),
                    ),
                    const SizedBox(height: 14),
                    // Style options
                    _RingStyleRow(
                      current: _ringStyle,
                      onStyle: (s) => setState(() => _ringStyle = s),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ))),
        ],
      ),
    );
  }
}

// ── 3D Spinning Ring Widget ────────────────────────────────────────────────

class _SpinRingWidget extends StatefulWidget {
  final Color color;
  final RingStyle style;

  const _SpinRingWidget({required this.color, required this.style});

  @override
  State<_SpinRingWidget> createState() => _SpinRingWidgetState();
}

class _SpinRingWidgetState extends State<_SpinRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _rotY = 0;
  double _rotX = 0.42; // initial tilt (same as before)
  double _rotZ = 0;
  double _velY = 0.010;
  double _velX = 0;
  DateTime _lastHaptic = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_tick)
      ..repeat();
  }

  void _tick() {
    setState(() {
      _velY = _velY * 0.97 + 0.010 * 0.03;
      _velX = _velX * 0.93;
      _rotY += _velY;
      _rotX += _velX;
      _rotZ += 0.0015; // very slow Z drift for depth interest
    });
    if (_velY.abs() > 0.06) {
      final now = DateTime.now();
      if (now.difference(_lastHaptic).inMilliseconds > 90) {
        _lastHaptic = now;
        HapticFeedback.selectionClick();
        SystemSound.play(SystemSoundType.click);
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _velY = d.delta.dx * 0.030;
      _velX = d.delta.dy * 0.020;
    });
  }

  void _onTap() => setState(() {
    _velY = 0.20;
    _velX = 0.06;
  });

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onTap: _onTap,
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: CustomPaint(
          painter: _RingPainter(
            rotY: _rotY,
            rotX: _rotX,
            rotZ: _rotZ,
            ringColor: widget.color,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}

// ── Ring Painter ───────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double rotY;
  final double rotX;
  final double rotZ;
  final Color ringColor;
  final RingStyle style;

  const _RingPainter({
    required this.rotY,
    required this.rotX,
    required this.rotZ,
    required this.ringColor,
    required this.style,
  });

  static const double _ringRadius  = 100.0;
  static const double _camDist     = 480.0;
  static const int    _numBeads    = 52;
  static const int    _numSegments = 220;

  (double x2d, double y2d, double z3d) _project(double theta, double cx, double cy) {
    // Y rotation (spin)
    final dTheta = theta - rotY;
    final x1 = _ringRadius * cos(dTheta);
    final zPre = _ringRadius * sin(dTheta);
    // X rotation (tilt)
    final y1 = -zPre * sin(rotX);
    final z1 = zPre * cos(rotX);
    // Z rotation (slow drift)
    final x2 = x1 * cos(rotZ) - y1 * sin(rotZ);
    final y2 = x1 * sin(rotZ) + y1 * cos(rotZ);
    final z2 = z1;
    final scale = _camDist / (_camDist + z2);
    return (cx + x2 * scale, cy + y2 * scale, z2);
  }

  void _drawRingBand(Canvas canvas, double cx, double cy, bool front) {
    final path = Path();
    bool started = false;
    for (int i = 0; i <= _numSegments; i++) {
      final theta = (i / _numSegments) * 2 * pi;
      final (x, y, z) = _project(theta, cx, cy);
      final isFront = z < 0;
      if (isFront != front) { started = false; continue; }
      if (!started) { path.moveTo(x, y); started = true; }
      else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, Paint()
      ..color = front ? ringColor.withAlpha(170) : ringColor.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = front ? 1.8 : 1.0);
  }

  void _drawBeads(Canvas canvas, double cx, double cy) {
    final beads = <({double x, double y, double z, int i})>[];
    for (int i = 0; i < _numBeads; i++) {
      final theta = (i / _numBeads) * 2 * pi;
      final (x, y, z) = _project(theta, cx, cy);
      beads.add((x: x, y: y, z: z, i: i));
    }
    beads.sort((a, b) => b.z.compareTo(a.z));

    for (final b in beads) {
      final depth = (1.0 - (b.z + _ringRadius) / (2 * _ringRadius)).clamp(0.0, 1.0);
      final alpha = (50 + depth * 205).toInt().clamp(0, 255);
      final radius = 2.2 + depth * 5.0;
      final clr = ringColor.withAlpha(alpha);

      if (depth > 0.55) {
        canvas.drawCircle(
          Offset(b.x, b.y),
          radius * 2.8,
          Paint()
            ..color = ringColor.withAlpha((depth * 40).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      switch (style) {
        case RingStyle.beads:
          canvas.drawCircle(Offset(b.x, b.y), radius, Paint()..color = clr);
        case RingStyle.discs:
          canvas.drawOval(
            Rect.fromCenter(center: Offset(b.x, b.y), width: radius * 2.4, height: radius * 1.1),
            Paint()..color = clr,
          );
        case RingStyle.stars:
          canvas.drawPath(_starPath(b.x, b.y, radius + 1.5), Paint()..color = clr);
        case RingStyle.diamonds:
          canvas.drawPath(_diamondPath(b.x, b.y, radius + 1.5), Paint()..color = clr);
        case RingStyle.hollow:
          canvas.drawCircle(Offset(b.x, b.y), radius, Paint()..color = clr..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  Path _starPath(double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) - pi / 2;
      final radius = i.isEven ? r : r * 0.44;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  Path _diamondPath(double cx, double cy, double r) {
    return Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.65, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.65, cy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    _drawRingBand(canvas, cx, cy, false);
    _drawRingBand(canvas, cx, cy, true);
    _drawBeads(canvas, cx, cy);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.rotY != rotY || old.rotX != rotX || old.rotZ != rotZ ||
      old.ringColor != ringColor || old.style != style;
}

// ── Ring color & style controls ────────────────────────────────────────────

class _RingColorRow extends StatelessWidget {
  final Color current;
  final void Function(Color) onColor;

  const _RingColorRow({required this.current, required this.onColor});

  static const _presets = [SL.lime, SL.pink, SL.blue, SL.red, SL.white, Color(0xFFFFD700)];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._presets.map((c) => GestureDetector(
          onTap: () => onColor(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26, height: 26,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: current == c ? Border.all(color: SL.white, width: 2) : null,
              boxShadow: current == c ? [BoxShadow(color: c.withAlpha(80), blurRadius: 8)] : null,
            ),
          ),
        )),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: SL.elevated,
              shape: BoxShape.circle,
              border: Border.all(color: SL.border),
            ),
            child: const Icon(Icons.add_rounded, size: 14, color: SL.grey),
          ),
        ),
      ],
    );
  }

  void _openPicker(BuildContext context) {
    Color temp = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: SL.surface,
          title: const Text('RING COLOR', style: TextStyle(color: SL.white, fontWeight: FontWeight.w800, fontSize: 15)),
          content: SingleChildScrollView(
            child: ColorPicker(pickerColor: temp, onColorChanged: (c) { setS(() => temp = c); }),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); onColor(temp); },
              child: const Text('DONE', style: TextStyle(color: SL.lime, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingStyleRow extends StatelessWidget {
  final RingStyle current;
  final void Function(RingStyle) onStyle;

  const _RingStyleRow({required this.current, required this.onStyle});

  @override
  Widget build(BuildContext context) {
    const labels = {
      RingStyle.beads:    (icon: Icons.circle, label: 'BEADS'),
      RingStyle.discs:    (icon: Icons.lens_outlined, label: 'DISCS'),
      RingStyle.stars:    (icon: Icons.star_rounded, label: 'STARS'),
      RingStyle.diamonds: (icon: Icons.diamond_rounded, label: 'DIAMOND'),
      RingStyle.hollow:   (icon: Icons.radio_button_unchecked, label: 'HOLLOW'),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RingStyle.values.map((s) {
        final active = s == current;
        final info = labels[s]!;
        return GestureDetector(
          onTap: () => onStyle(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? SL.lime.withAlpha(25) : SL.elevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? SL.lime.withAlpha(80) : Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(info.icon, size: 12, color: active ? SL.lime : SL.grey),
                const SizedBox(width: 5),
                Text(info.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? SL.lime : SL.grey, letterSpacing: 1)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Signal bars ────────────────────────────────────────────────────────────

class _SignalBars extends StatelessWidget {
  final int? rssi;
  const _SignalBars({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final Color barColor;
    final int active;
    if (rssi == null) {
      barColor = SL.grey;
      active = 0;
    } else if (rssi! > -60) {
      barColor = SL.lime;
      active = 3;
    } else if (rssi! > -75) {
      barColor = SL.yellow;
      active = 2;
    } else {
      barColor = SL.red;
      active = 1;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) => Container(
        width: 5,
        height: 7.0 + i * 5.5,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: i < active ? barColor : SL.darkGrey,
          borderRadius: BorderRadius.circular(2),
        ),
      )),
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────

class _ConnectionCard extends StatelessWidget {
  final bool connected;
  const _ConnectionCard({required this.connected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: connected ? SL.lime.withAlpha(15) : SL.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: connected ? SL.lime.withAlpha(80) : SL.border, width: connected ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: connected ? SL.lime.withAlpha(25) : SL.elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(connected ? Icons.watch_rounded : Icons.watch_off_rounded, color: connected ? SL.lime : SL.grey, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connected ? 'SafeLink Band' : 'No band paired',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: connected ? SL.lime : SL.white)),
                const SizedBox(height: 2),
                Text(connected ? 'BLE connected — monitoring' : 'Scanning for SafeLink-A or B...',
                    style: const TextStyle(fontSize: 12, color: SL.grey, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          if (!connected)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: SL.grey)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatCard({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SL.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String text;
  const _AboutRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5, right: 10), decoration: const BoxDecoration(color: SL.lime, shape: BoxShape.circle)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: SL.grey, fontWeight: FontWeight.w400))),
      ],
    );
  }
}
