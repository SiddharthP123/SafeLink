import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WaveBackground extends StatefulWidget {
  final List<Color> layerColors;

  // Default: logo palette — orange → pink → cyan → purple (back to front)
  static const defaultColors = [
    Color(0xFFFF9500),
    Color(0xFFFF3FA4),
    Color(0xFF00B4FF),
    Color(0xFFAA44FF),
  ];

  // Map screen — COMFORT alert (amber/gold tones)
  static const comfortColors = [
    Color(0xFFCC8800),
    Color(0xFFFFAA00),
    Color(0xFFFFCC00),
    Color(0xFFFFE680),
  ];

  // Map screen — SOS alert (red tones)
  static const sosColors = [
    Color(0xFF7B0000),
    Color(0xFFBB1100),
    Color(0xFFFF3B3B),
    Color(0xFFFF7070),
  ];

  const WaveBackground({
    super.key,
    this.layerColors = defaultColors,
  });

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _GradientWavePainter(
          layerColors: widget.layerColors,
          phase: _ctrl.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GradientWavePainter extends CustomPainter {
  final List<Color> layerColors;
  final double phase;

  const _GradientWavePainter({
    required this.layerColors,
    required this.phase,
  });

  // Four layers — back to front (largest to smallest)
  // Waves travel right-to-left (standard sine phase) with different speeds
  static const _layers = [
    (heightFrac: 0.72, amp: 28.0, alpha: 80, freq: 1.1, phaseOff: 0.00),
    (heightFrac: 0.56, amp: 24.0, alpha: 70, freq: 1.4, phaseOff: 0.40),
    (heightFrac: 0.41, amp: 20.0, alpha: 60, freq: 1.7, phaseOff: 0.80),
    (heightFrac: 0.27, amp: 16.0, alpha: 50, freq: 2.1, phaseOff: 1.20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int li = 0; li < _layers.length; li++) {
      final l = _layers[li];
      final layerColor = li < layerColors.length ? layerColors[li] : layerColors.last;

      // Waves move left-to-right: use subtraction on phase
      final phaseShift = phase * 2 * pi - l.phaseOff * pi;
      final baseY = size.height * (1.0 - l.heightFrac);

      final path = Path();
      path.moveTo(0, baseY + l.amp * sin(phaseShift));

      for (double x = 0; x <= size.width + 2; x += 3) {
        final y = baseY +
            l.amp * sin(x / size.width * l.freq * 2 * pi - phaseShift);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      // Vertical gradient: transparent at wave crest → opaque at bottom
      final gradient = ui.Gradient.linear(
        Offset(0, baseY - l.amp),
        Offset(0, size.height),
        [layerColor.withAlpha(0), layerColor.withAlpha(l.alpha)],
      );

      canvas.drawPath(path, Paint()..shader = gradient);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientWavePainter old) =>
      old.phase != phase || old.layerColors != layerColors;
}
