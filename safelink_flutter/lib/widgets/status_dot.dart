import 'package:flutter/material.dart';

/// Small coloured dot with a text label indicating BLE connection state.
/// Green (#1D9E75) when connected, grey when searching/disconnected.
class StatusDot extends StatelessWidget {
  final bool connected;

  const StatusDot({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? const Color(0xFF1D9E75) // teal/success
        : const Color(0xFF9E9E9E); // grey

    final label = connected ? 'Band connected' : 'Searching for band...';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: connected
                ? [
                    BoxShadow(
                      color: color.withAlpha(120),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
