import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/wave_background.dart';
// sign_in_with_apple kept as dependency but Apple button removed (capability not set up)

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false; // default: sign-up first
  bool _loading = false;
  bool _obscure = true;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        final cred = await AuthService.signUp(_emailCtrl.text.trim(), _passwordCtrl.text);
        final name = _nameCtrl.text.trim();
        if (name.isNotEmpty) await cred.user?.updateDisplayName(name);
        await AuthService.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (mounted) _showError(e.toString().contains('cancelled') ? 'Sign-in cancelled.' : 'Google Sign-In requires Firebase setup. Run flutterfire configure first.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: SL.red),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account with that email.';
      case 'wrong-password':       return 'Incorrect password.';
      case 'email-already-in-use': return 'Email already registered.';
      case 'invalid-email':        return 'Invalid email address.';
      case 'weak-password':        return 'Password must be 6+ characters.';
      default:                     return 'Something went wrong. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg,
      body: Stack(
        children: [
          // Animated lime wave background
          Positioned.fill(
            child: const IgnorePointer(child: WaveBackground()),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Logo pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: SL.lime, borderRadius: BorderRadius.circular(100)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 12, color: SL.bg),
                          SizedBox(width: 5),
                          Text('SAFELINK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Headline
                    Text(
                      _isLogin ? 'WELCOME\nBACK.' : 'WELCOME.',
                      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: SL.white, height: 0.95, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? 'Sign in to keep your\nconnection active.'
                          : 'Set up your SafeLink\nprofile to get started.',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: SL.grey, height: 1.5),
                    ),
                    const SizedBox(height: 40),

                    // Name field (sign up only)
                    if (!_isLogin) ...[
                      _BoldField(
                        controller: _nameCtrl,
                        label: 'YOUR NAME',
                        hint: 'e.g. Siddharth',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _BoldField(
                      controller: _emailCtrl,
                      label: 'EMAIL',
                      hint: 'you@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 16),

                    _BoldField(
                      controller: _passwordCtrl,
                      label: 'PASSWORD',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: SL.grey, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 36),

                    // Primary CTA button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _loading ? SL.border : SL.lime,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: SL.lime),
                                )
                              : Text(
                                  _isLogin ? 'SIGN IN' : 'CREATE AN ACCOUNT',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: SL.bg, letterSpacing: 1.5),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: SL.border)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(fontSize: 11, color: SL.grey, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                        const Expanded(child: Divider(color: SL.border)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-In
                    _SocialButton(
                      onTap: _loading ? null : _googleSignIn,
                      icon: const _GoogleIcon(),
                      label: _isLogin ? 'Continue with Google' : 'Sign up with Google',
                    ),
                    const SizedBox(height: 24),

                    // Toggle
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = !_isLogin),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: SL.grey, fontWeight: FontWeight.w400),
                            children: [
                              TextSpan(
                                text: _isLogin ? "Don't have an account? " : 'Already have an account? ',
                              ),
                              TextSpan(
                                text: _isLogin ? 'Create one.' : 'Sign in.',
                                style: const TextStyle(color: SL.lime, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared input field ─────────────────────────────────────────────────────

class _BoldField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _BoldField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SL.grey, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: SL.white, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SL.darkGrey, fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: SL.grey, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: SL.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.lime, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.red)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: SL.red, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ── Social sign-in button ──────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;

  const _SocialButton({required this.onTap, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: SL.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SL.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SL.white)),
          ],
        ),
      ),
    );
  }
}

// ── Google "G" logo painted ────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final segments = [
      (start: -0.17, sweep: 0.5, color: const Color(0xFF4285F4)),
      (start: 0.33,  sweep: 0.5, color: const Color(0xFF34A853)),
      (start: 0.83,  sweep: 0.5, color: const Color(0xFFFBBC05)),
      (start: 1.33,  sweep: 0.34, color: const Color(0xFFEA4335)),
    ];
    const pi = 3.1415926535;
    for (final seg in segments) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        seg.start * pi,
        seg.sweep * pi,
        false,
        Paint()..color = seg.color..strokeWidth = 3..style = PaintingStyle.stroke,
      );
    }
    // White bar for cut-out
    canvas.drawRect(Rect.fromLTWH(c.dx, c.dy - 2, r + 2, 4), Paint()..color = const Color(0xFF0D0D0D));
    canvas.drawLine(Offset(c.dx, c.dy - 2), Offset(c.dx + r, c.dy - 2), Paint()..color = const Color(0xFF4285F4)..strokeWidth = 2.5);
    canvas.drawLine(Offset(c.dx, c.dy + 2), Offset(c.dx + r, c.dy + 2), Paint()..color = const Color(0xFF4285F4)..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
