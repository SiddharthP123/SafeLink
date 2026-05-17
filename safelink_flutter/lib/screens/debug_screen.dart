import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

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
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _log.insert(0, _LogEntry(timestamp: timestamp, message: message, isError: isError));
    });
  }

  Future<void> _simulate(String type) async {
    if (_busy) return;
    setState(() => _busy = true);
    _appendLog('[$type] Getting current GPS location...');

    try {
      final position = await LocationService.getCurrentLocation();
      final lat = position.latitude;
      final lng = position.longitude;
      _appendLog('[$type] GPS acquired: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}');
      _appendLog('[$type] Writing to Firestore alerts/active...');
      await FirebaseService.sendAlert(type, lat, lng);
      _appendLog('[$type] Alert sent. Firestore updated.');
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
      appBar: AppBar(
        title: const Text('Debug / Simulator'),
        backgroundColor: const Color(0xFF534AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Buttons area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // COMFORT button
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _simulate('COMFORT'),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Simulate short press (COMFORT)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA7517),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // SOS button
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _simulate('SOS'),
                  icon: const Icon(Icons.warning_rounded),
                  label: const Text('Simulate long press (SOS)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE24B4A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                if (_busy) ...[
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF534AB7),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Working...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF534AB7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Log feed header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Action Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_log.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _log.clear()),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF534AB7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Log entries
          Expanded(
            child: _log.isEmpty
                ? const Center(
                    child: Text(
                      'Tap a button above to simulate an alert.\n'
                      'Actions will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _log.length,
                    itemBuilder: (context, index) {
                      final entry = _log[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.timestamp,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: entry.isError
                                      ? const Color(0xFFE24B4A)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String timestamp;
  final String message;
  final bool isError;

  const _LogEntry({
    required this.timestamp,
    required this.message,
    this.isError = false,
  });
}
