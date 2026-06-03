import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart' as safelink_fb;
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SafeLinkApp());
}

class SafeLinkApp extends StatelessWidget {
  const SafeLinkApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeLink',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SL.bg,
        colorScheme: const ColorScheme.dark(
          primary: SL.lime,
          secondary: SL.pink,
          surface: SL.surface,
          error: SL.red,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              color: SL.white, fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(
              color: SL.white, fontWeight: FontWeight.w400),
          titleMedium: TextStyle(
              color: SL.white, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: SL.white, fontWeight: FontWeight.w800),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: SL.surface,
          contentTextStyle: TextStyle(color: SL.white),
        ),
      ),
      home: const _StartupRouter(),
    );
  }
}

// ---------------------------------------------------------------------------
// Startup router: onboarding → auth → email verification → main app
// ---------------------------------------------------------------------------

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() =>
        _onboardingDone =
            prefs.getBool('safelink_onboarding_complete') ?? false);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('safelink_onboarding_complete', true);
    if (!mounted) return;
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) return const _SplashScreen();

    if (!_onboardingDone!) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) return const AuthScreen();
        if (!user.emailVerified) {
          return const _EmailVerificationGate();
        }
        return const _RootNavigator();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Email verification gate — shown after signup until user clicks link
// ---------------------------------------------------------------------------

class _EmailVerificationGate extends StatefulWidget {
  const _EmailVerificationGate();

  @override
  State<_EmailVerificationGate> createState() =>
      _EmailVerificationGateState();
}

class _EmailVerificationGateState
    extends State<_EmailVerificationGate> {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  bool _resendEnabled = true;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) async {
      final verified = await AuthService.isEmailVerified();
      if (verified && mounted) {
        _pollTimer?.cancel();
        // Navigate to root — StreamBuilder will re-evaluate
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const _RootNavigator()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _resend() async {
    await AuthService.sendEmailVerification();
    setState(() {
      _resendEnabled = false;
      _countdown = 60;
    });
    _cooldownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown <= 0) {
        _cooldownTimer?.cancel();
        if (mounted) setState(() => _resendEnabled = true);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: SL.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: SL.lime,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'SAFELINK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: SL.bg,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'CHECK YOUR\nEMAIL.',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: SL.white,
                  height: 0.95,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'We sent a verification link to\n$email',
                style: const TextStyle(
                    fontSize: 14, color: SL.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SL.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SL.border),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: SL.lime),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Waiting for verification…',
                      style: TextStyle(
                          fontSize: 14, color: SL.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _resendEnabled ? _resend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _resendEnabled
                        ? SL.surface
                        : SL.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _resendEnabled
                          ? SL.border
                          : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _resendEnabled
                        ? 'RESEND EMAIL'
                        : 'RESEND IN ${_countdown}s',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _resendEnabled
                          ? SL.white
                          : SL.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => AuthService.signOut(),
                child: const Center(
                  child: Text(
                    'Sign out',
                    style: TextStyle(fontSize: 13, color: SL.grey),
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

// ---------------------------------------------------------------------------
// Splash screen
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SL.bg,
      body: Center(
        child: Text(
          'SAFELINK',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: SL.lime,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Root navigator with bottom nav
// ---------------------------------------------------------------------------

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  int _currentIndex = 0;

  static const _tabColors = [
    Color(0xFFFF9500),  // Home   — orange
    Color(0xFFFF3FA4),  // Map    — pink
    SL.lime,            // Contacts — lime/green
    Color(0xFF00B4FF),  // Settings — cyan
    Color(0xFFAA44FF),  // Debug  — purple
  ];
  StreamSubscription<Map<String, dynamic>?>? _alertSub;
  int _lastAlertTimestamp = 0;
  bool _dialogShowing = false;

  static const List<Widget> _screens = [
    HomeScreen(),
    MapScreen(),
    ContactsScreen(),
    SettingsScreen(),
    DebugScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForAlerts();
    NotificationService.requestPermissions();
  }

  void _listenForAlerts() {
    _alertSub =
        safelink_fb.FirebaseService.alertStream().listen((alert) async {
      if (!mounted || alert == null || alert['seen'] == true) return;
      final ts = alert['timestamp'] as int? ?? 0;
      if (ts == _lastAlertTimestamp || _dialogShowing) return;
      _lastAlertTimestamp = ts;
      final type = alert['type'] as String;
      final lat  = alert['lat']  as double? ?? 0.0;
      final lng  = alert['lng']  as double? ?? 0.0;
      // Always fire the local notification (visible even when app is backgrounded)
      await NotificationService.showAlert(type: type, lat: lat, lng: lng);
      if (!mounted) return;
      // Respect COMFORT preference for the in-app dialog
      if (type == 'COMFORT') {
        final enabled = await NotificationService.comfortAlertsEnabled();
        if (!enabled || !mounted) return;
      }
      _showAlertDialog(alert);
    });
  }

  void _showAlertDialog(Map<String, dynamic> alert) {
    final type = alert['type'] as String;
    final lat = alert['lat'] as double;
    final lng = alert['lng'] as double;
    final isSOS = type == 'SOS';
    final accentColor = isSOS ? SL.red : SL.yellow;

    _dialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: !isSOS,
      barrierColor: Colors.black.withAlpha(180),
      builder: (ctx) => Dialog(
        backgroundColor: SL.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SL.bg,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSOS ? 'SOS\nALERT' : 'COMFORT\nALERT',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  height: 0.95,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isSOS
                    ? 'Your paired user needs urgent help!'
                    : 'Your paired user sent a comfort check-in.',
                style: const TextStyle(
                    fontSize: 14,
                    color: SL.grey,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 8),
              Text(
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: SL.darkGrey,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    safelink_fb.FirebaseService.markSeen();
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SL.bg,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _dialogShowing = false);
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: SL.border, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: SL.bg,
          indicatorColor: _tabColors[_currentIndex].withAlpha(35),
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) =>
              setState(() => _currentIndex = i),
          labelBehavior:
              NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, color: SL.grey),
              selectedIcon: Icon(Icons.home_rounded, color: _tabColors[0]),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined, color: SL.grey),
              selectedIcon: Icon(Icons.map_rounded, color: _tabColors[1]),
              label: 'Map',
            ),
            NavigationDestination(
              icon: const Icon(Icons.contacts_outlined, color: SL.grey),
              selectedIcon: Icon(Icons.contacts_rounded, color: _tabColors[2]),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined, color: SL.grey),
              selectedIcon: Icon(Icons.settings_rounded, color: _tabColors[3]),
              label: 'Settings',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bug_report_outlined, color: SL.grey),
              selectedIcon: Icon(Icons.bug_report_rounded, color: _tabColors[4]),
              label: 'Debug',
            ),
          ],
        ),
      ),
    );
  }
}
