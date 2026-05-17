import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'alerts';
  static const String _document = 'active';

  /// Write (or overwrite) the active alert document.
  /// [type] must be 'COMFORT' or 'SOS'.
  static Future<void> sendAlert(String type, double lat, double lng) async {
    await _db.collection(_collection).doc(_document).set({
      'type': type,
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'seen': false,
    });
  }

  /// Mark the current alert as seen so it is not shown again after dismiss.
  static Future<void> markSeen() async {
    await _db.collection(_collection).doc(_document).update({'seen': true});
  }

  /// Real-time stream of the active alert document.
  /// Emits null when the document does not exist or has been seen.
  /// Emits a Map<String, dynamic> with keys: type, lat, lng, timestamp, seen.
  static Stream<Map<String, dynamic>?> alertStream() {
    return _db
        .collection(_collection)
        .doc(_document)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      return {
        'type': data['type'] as String? ?? 'COMFORT',
        'lat': (data['lat'] as num?)?.toDouble() ?? 0.0,
        'lng': (data['lng'] as num?)?.toDouble() ?? 0.0,
        'timestamp': data['timestamp'] as int? ?? 0,
        'seen': data['seen'] as bool? ?? false,
      };
    });
  }
}
