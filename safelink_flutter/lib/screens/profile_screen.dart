import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../widgets/wave_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl     = TextEditingController();
  final _uniCtrl      = TextEditingController();
  final _addr1Ctrl    = TextEditingController();
  final _addr2Ctrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  DateTime? _dob;
  Uint8List? _photoBytes;
  bool _comfortAlerts = true;
  bool _loading  = true;
  bool _saving   = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data  = await ProfileService.loadProfile();
    final user  = AuthService.currentUser;
    final photo = await ProfileService.getProfilePhotoBytes();
    final comfort = await NotificationService.comfortAlertsEnabled();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text   = data?['name']       as String? ?? user?.displayName ?? '';
      _uniCtrl.text    = data?['university'] as String? ?? '';
      _addr1Ctrl.text  = data?['address1']   as String? ?? '';
      _addr2Ctrl.text  = data?['address2']   as String? ?? '';
      _phoneCtrl.text  = data?['phone']      as String? ?? '';
      final dobStr     = data?['dateOfBirth'] as String?;
      if (dobStr != null && dobStr.isNotEmpty) _dob = DateTime.tryParse(dobStr);
      _photoBytes    = photo;
      _comfortAlerts = comfort;
      _loading       = false;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 400);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await ProfileService.saveProfilePhoto(base64Encode(bytes));
    if (mounted) setState(() => _photoBytes = bytes);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: SL.lime, onPrimary: SL.bg, surface: SL.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProfileService.saveProfile(
        name:        _nameCtrl.text.trim(),
        dateOfBirth: _dob != null ? _dob!.toIso8601String().split('T')[0] : '',
        university:  _uniCtrl.text.trim(),
        address1:    _addr1Ctrl.text.trim(),
        address2:    _addr2Ctrl.text.trim(),
        phone:       _phoneCtrl.text.trim(),
      );
      await NotificationService.setComfortAlerts(_comfortAlerts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uniCtrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: SL.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: WaveBackground())),
          SafeArea(child: _loading
            ? const Center(child: CircularProgressIndicator(color: SL.lime))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                children: [
                  // Header row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: SL.border)),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: SL.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 2)),
                          Text('PROFILE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: SL.white, height: 1, letterSpacing: -0.5)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Avatar ──────────────────────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showPhotoOptions(),
                          child: Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              color: _photoBytes == null ? SL.lime : null,
                              borderRadius: BorderRadius.circular(26),
                              border: _photoBytes != null ? Border.all(color: SL.border, width: 2) : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _photoBytes != null
                                ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                                : Center(child: Text(initial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SL.bg))),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => _showPhotoOptions(),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: SL.bg),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email (read-only) ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SL.border)),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline_rounded, color: SL.grey, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: SL.white, fontWeight: FontWeight.w500))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: user?.emailVerified == true ? SL.lime.withAlpha(30) : SL.yellow.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?.emailVerified == true ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, color: user?.emailVerified == true ? SL.lime : SL.yellow),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Profile fields ───────────────────────────────────────
                  _ProfileField(controller: _nameCtrl, label: 'DISPLAY NAME', hint: 'Your name', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _ProfileField(controller: _phoneCtrl, label: 'PHONE NUMBER', hint: '+44 7700 000000', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _ProfileField(controller: _uniCtrl, label: 'UNIVERSITY', hint: 'e.g. Imperial College London', icon: Icons.school_outlined),
                  const SizedBox(height: 12),
                  _ProfileField(controller: _addr1Ctrl, label: 'ADDRESS LINE 1', hint: 'Street address', icon: Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _ProfileField(controller: _addr2Ctrl, label: 'ADDRESS LINE 2', hint: 'City, postcode (optional)', icon: Icons.location_city_outlined),
                  const SizedBox(height: 12),

                  // DOB picker
                  GestureDetector(
                    onTap: _pickDob,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: SL.border)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: SL.grey, size: 18),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DATE OF BIRTH', style: TextStyle(fontSize: 10, color: SL.grey, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                              const SizedBox(height: 3),
                              Text(
                                _dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Tap to set',
                                style: TextStyle(fontSize: 14, color: _dob != null ? SL.white : SL.darkGrey, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: SL.darkGrey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Notification preferences ─────────────────────────────
                  const Text('NOTIFICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: SL.border)),
                    child: Column(
                      children: [
                        _NotifTile(
                          title: 'Comfort alerts',
                          subtitle: 'Show in-app popup when your partner sends a comfort check-in.',
                          value: _comfortAlerts,
                          onChanged: (v) => setState(() => _comfortAlerts = v),
                        ),
                        const Divider(height: 1, color: SL.border),
                        _NotifTile(
                          title: 'SOS alerts',
                          subtitle: 'Always on — cannot be disabled for safety.',
                          value: true,
                          onChanged: null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Save button ──────────────────────────────────────────
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _saving ? SL.elevated : SL.lime,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: SL.bg))
                          : const Text('SAVE CHANGES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
          ),  // SafeArea
        ],
      ),  // Stack
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SL.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: SL.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: SL.lime),
              title: const Text('Choose from library', style: TextStyle(color: SL.white)),
              onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: SL.blue),
              title: const Text('Take a photo', style: TextStyle(color: SL.white)),
              onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.camera); },
            ),
            if (_photoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: SL.red),
                title: const Text('Remove photo', style: TextStyle(color: SL.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ProfileService.clearProfilePhoto();
                  if (mounted) setState(() => _photoBytes = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Profile field ──────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;

  const _ProfileField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(color: SL.white, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SL.darkGrey, fontSize: 14),
            prefixIcon: Icon(icon, color: SL.grey, size: 20),
            filled: true,
            fillColor: SL.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.lime, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── Notification toggle tile ───────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool)? onChanged;

  const _NotifTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onChanged == null ? SL.grey : SL.white)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: SL.grey, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SL.lime,
            activeTrackColor: SL.lime.withAlpha(50),
            inactiveThumbColor: SL.darkGrey,
            inactiveTrackColor: SL.elevated,
          ),
        ],
      ),
    );
  }
}
