import 'package:flutter/material.dart';

/// Dismissable alert card displayed as an overlay when a wristband alert fires.
/// [type]      — 'COMFORT' or 'SOS'
/// [lat]/[lng] — coordinates from Firestore
/// [onDismiss] — called when the user taps Dismiss
class AlertBanner extends StatelessWidget {
  final String type;
  final double lat;
  final double lng;
  final VoidCallback onDismiss;

  const AlertBanner({
    super.key,
    required this.type,
    required this.lat,
    required this.lng,
    required this.onDismiss,
  });

  bool get _isSOS => type == 'SOS';

  Color get _backgroundColor =>
      _isSOS ? const Color(0xFFE24B4A) : const Color(0xFFBA7517);

  String get _title => _isSOS ? 'SOS ALERT' : 'COMFORT ALERT';

  String get _subtitle => _isSOS
      ? 'Your paired user needs urgent help!'
      : 'Your paired user sent a comfort check-in.';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _backgroundColor.withAlpha(100),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isSOS ? Icons.warning_rounded : Icons.favorite_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Location: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
