import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../widgets/wave_background.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Uint8List? _profilePhoto;
  String _selectedBand = NotificationService.bandAName;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
    _loadBand();
  }

  Future<void> _loadPhoto() async {
    final photo = await ProfileService.getProfilePhotoBytes();
    if (mounted) setState(() => _profilePhoto = photo);
  }

  Future<void> _loadBand() async {
    final band = await NotificationService.getBandName();
    if (mounted) setState(() => _selectedBand = band);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: SL.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: WaveBackground())),
          SafeArea(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          children: [
            // Header
            const Text('APP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 2)),
            const Text('SETTINGS', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: SL.white, height: 1, letterSpacing: -1)),
            const SizedBox(height: 28),

            // ── MY PROFILE (large card) ───────────────────────────────────
            const Text('MY PROFILE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
            const SizedBox(height: 12),

            if (user != null)
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadPhoto()),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SL.blue.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: _profilePhoto == null ? SL.lime : null,
                              borderRadius: BorderRadius.circular(18),
                              border: _profilePhoto != null ? Border.all(color: SL.border, width: 2) : null,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _profilePhoto != null
                                ? Image.memory(_profilePhoto!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      (user.displayName?.isNotEmpty == true) ? user.displayName![0].toUpperCase() : user.email![0].toUpperCase(),
                                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: SL.bg),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName?.isNotEmpty == true ? user.displayName! : 'SafeLink User',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SL.white),
                                ),
                                const SizedBox(height: 3),
                                Text(user.email ?? '', style: const TextStyle(fontSize: 12, color: SL.grey)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: user.emailVerified ? SL.lime.withAlpha(25) : SL.yellow.withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        user.emailVerified ? '✓ VERIFIED' : '⏳ PENDING',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: user.emailVerified ? SL.lime : SL.yellow, letterSpacing: 1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: SL.darkGrey, size: 22),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: SL.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SL.blue.withAlpha(50)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('EDIT PROFILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: SL.blue, letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // ── MY BAND ──────────────────────────────────────────────────
            const Text('MY BAND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: SL.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONNECT TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SL.darkGrey, letterSpacing: 1)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _BandChip(
                        label: 'BAND A',
                        selected: _selectedBand == NotificationService.bandAName,
                        onTap: () async {
                          await NotificationService.setBandName(NotificationService.bandAName);
                          if (mounted) setState(() => _selectedBand = NotificationService.bandAName);
                        },
                      ),
                      const SizedBox(width: 12),
                      _BandChip(
                        label: 'BAND B',
                        selected: _selectedBand == NotificationService.bandBName,
                        onTap: () async {
                          await NotificationService.setBandName(NotificationService.bandBName);
                          if (mounted) setState(() => _selectedBand = NotificationService.bandBName);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Changes take effect on next app launch.', style: TextStyle(fontSize: 11, color: SL.darkGrey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Sign out (directly below profile) ────────────────────────
            GestureDetector(
              onTap: () async => AuthService.signOut(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: SL.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SL.red.withAlpha(50)),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: SL.red, size: 18),
                    SizedBox(width: 8),
                    Text('SIGN OUT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SL.red, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── About ────────────────────────────────────────────────────
            const Text('ABOUT THE APP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: SL.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: SL.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SafeLink', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SL.white)),
                          Text('v1.2.0 (Beta · Pilot Stage)', style: TextStyle(fontSize: 11, color: SL.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: SL.border),
                  const SizedBox(height: 14),
                  _AboutRow(icon: Icons.school_outlined, label: 'Institution', value: 'Imperial College London'),
                  const SizedBox(height: 10),
                  _AboutRow(icon: Icons.menu_book_outlined, label: 'Course', value: 'DESE40004 — Design Engineering'),
                  const SizedBox(height: 10),
                  _AboutRow(icon: Icons.group_outlined, label: 'Team', value: '5 Design Engineering students'),
                  const SizedBox(height: 10),
                  _AboutRow(icon: Icons.info_outline_rounded, label: 'Stage', value: 'Pilot prototype — not for production use'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        )),
        ],
      ),
    );
  }
}

class _BandChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BandChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? SL.lime.withAlpha(25) : SL.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? SL.lime.withAlpha(100) : SL.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? SL.lime : SL.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AboutRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: SL.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: SL.darkGrey, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text(value, style: const TextStyle(fontSize: 13, color: SL.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
