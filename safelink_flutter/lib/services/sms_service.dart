import 'package:url_launcher/url_launcher.dart';
import 'contacts_service.dart';
import 'auth_service.dart';

class SmsService {
  /// Opens the native SMS compose sheet pre-filled with all emergency contacts
  /// and an SOS message containing the GPS location + Google Maps link.
  ///
  /// Returns true if the SMS sheet opened, false if no contacts are saved.
  static Future<bool> sendSosAlerts({
    required double lat,
    required double lng,
  }) async {
    final contacts = await ContactsService.getContacts();
    if (contacts.isEmpty) return false;

    final senderName =
        AuthService.currentUser?.displayName?.isNotEmpty == true
            ? AuthService.currentUser!.displayName!
            : 'SafeLink user';

    final mapsUrl =
        'https://maps.google.com/maps?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

    final body =
        '🆘 SOS ALERT from $senderName\n\n'
        'Live location: $mapsUrl\n\n'
        'Coordinates: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}\n\n'
        'Sent automatically via SafeLink.';

    // Comma-separated numbers → opens multi-recipient SMS on iOS & Android
    final phones = contacts.map((c) => c['phone']!).join(',');

    final uri = Uri(
      scheme: 'sms',
      path: phones,
      queryParameters: {'body': body},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }
}
