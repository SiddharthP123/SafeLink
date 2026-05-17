import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages emergency contacts, persisted securely on-device.
/// Each contact is a Map with keys 'name' and 'phone'.
class ContactsService {
  static const _storage = FlutterSecureStorage();
  static const String _key = 'emergency_contacts';

  /// Returns the list of saved emergency contacts.
  /// Returns an empty list if none are saved yet.
  static Future<List<Map<String, String>>> getContacts() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, String>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Overwrites the saved contacts list.
  static Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final encoded = jsonEncode(contacts);
    await _storage.write(key: _key, value: encoded);
  }

  /// Adds a single contact and persists the updated list.
  static Future<void> addContact(Map<String, String> contact) async {
    final existing = await getContacts();
    existing.add(contact);
    await saveContacts(existing);
  }

  /// Removes the contact at [index] and persists the updated list.
  static Future<void> removeContact(int index) async {
    final existing = await getContacts();
    if (index >= 0 && index < existing.length) {
      existing.removeAt(index);
      await saveContacts(existing);
    }
  }
}
