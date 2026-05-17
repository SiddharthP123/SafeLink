import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF534AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionTitle(title: 'App Information'),
          const SizedBox(height: 12),
          _InfoTile(label: 'App name', value: 'SafeLink'),
          _InfoTile(label: 'Version', value: '1.0.0 (build 1)'),
          _InfoTile(label: 'Platform', value: 'Flutter (Dart)'),
          const SizedBox(height: 28),

          _SectionTitle(title: 'Hardware / BLE'),
          const SizedBox(height: 12),
          _InfoTile(label: 'BLE mode', value: 'Mock (hardware not connected)'),
          _InfoTile(
            label: 'Service UUID',
            value: '12345678-1234-1234-1234-123456789012',
          ),
          _InfoTile(
            label: 'Button char UUID',
            value: '87654321-4321-4321-4321-210987654321',
          ),
          _InfoTile(
            label: 'Motor char UUID',
            value: 'AAAABBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF',
          ),
          const SizedBox(height: 28),

          _SectionTitle(title: 'Firebase'),
          const SizedBox(height: 12),
          _InfoTile(label: 'Project ID', value: 'connect-0-app'),
          _InfoTile(label: 'Collection', value: 'alerts / active'),
          _InfoTile(label: 'Realtime updates', value: 'Firestore snapshots'),
          const SizedBox(height: 28),

          _SectionTitle(title: 'Design System'),
          const SizedBox(height: 12),
          _ColorTile(label: 'Primary (purple)', hex: '#534AB7', color: const Color(0xFF534AB7)),
          _ColorTile(label: 'SOS (red)', hex: '#E24B4A', color: const Color(0xFFE24B4A)),
          _ColorTile(label: 'COMFORT (amber)', hex: '#BA7517', color: const Color(0xFFBA7517)),
          _ColorTile(label: 'Success (teal)', hex: '#1D9E75', color: const Color(0xFF1D9E75)),
          const SizedBox(height: 28),

          _SectionTitle(title: 'Team'),
          const SizedBox(height: 12),
          _InfoTile(label: 'Course', value: 'DESE40004 Human-Centred Design Engineering'),
          _InfoTile(label: 'Institution', value: 'Imperial College London'),
          _InfoTile(label: 'Team size', value: '5 students'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF534AB7).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF534AB7).withAlpha(40)),
            ),
            child: const Text(
              'When the ESP32-C3 hardware arrives:\n'
              '1. Replace ble_mock.dart calls with real BLE service\n'
              '2. Run flutterfire configure for production Firebase config\n'
              '3. Add google-services.json (Android) and\n'
              '   GoogleService-Info.plist (iOS)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF534AB7),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF534AB7),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
          const Spacer(),
          Text(
            hex,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
