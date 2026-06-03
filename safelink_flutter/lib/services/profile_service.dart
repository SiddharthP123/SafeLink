import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class ProfileService {
  static final _db = FirebaseFirestore.instance;
  static const _storage = FlutterSecureStorage();
  static const _photoKey = 'profile_photo_b64';

  static DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  static Future<Map<String, dynamic>?> loadProfile() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _doc(uid).get();
    return snap.data();
  }

  static Future<void> saveProfile({
    required String name,
    required String dateOfBirth,
    required String university,
    String address1 = '',
    String address2 = '',
    String phone = '',
  }) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await _doc(uid).set({
      'name': name,
      'dateOfBirth': dateOfBirth,
      'university': university,
      'address1': address1,
      'address2': address2,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (name.isNotEmpty) {
      await AuthService.updateDisplayName(name);
    }
  }

  static Future<String> getFirstName() async {
    final data = await loadProfile();
    final name = data?['name'] as String? ??
        AuthService.currentUser?.displayName ?? '';
    return name.split(' ').first;
  }

  // ── Profile photo (stored as base64 in secure storage) ──────────────────

  static Future<Uint8List?> getProfilePhotoBytes() async {
    final b64 = await _storage.read(key: _photoKey);
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfilePhoto(String base64Photo) async {
    await _storage.write(key: _photoKey, value: base64Photo);
  }

  static Future<void> clearProfilePhoto() async {
    await _storage.delete(key: _photoKey);
  }
}
