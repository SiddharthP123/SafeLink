import 'package:flutter/material.dart';
import '../app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      emoji: '🔗',
      title: 'WELCOME TO\nSAFELINK.',
      subtitle:
          'Stay connected to the people who matter most — with one press of a button.',
    ),
    _Slide(
      emoji: '📡',
      title: 'PAIR YOUR\nBAND.',
      subtitle:
          'Your SafeLink wristband connects via Bluetooth. The app pairs automatically whenever the band is in range.',
    ),
    _Slide(
      emoji: '🟡',
      title: 'COMFORT\nCHECK-IN.',
      subtitle:
          'Short press → your paired person\'s phone gets a gentle notification and your wristband gives a soft vibration.',
    ),
    _Slide(
      emoji: '🆘',
      title: 'SOS\nALERT.',
      subtitle:
          'Long press → urgent alert fires with your GPS coordinates. An SMS is sent to your emergency contacts instantly.',
    ),
    _Slide(
      emoji: '📍',
      title: 'REAL-TIME\nLOCATION.',
      subtitle:
          'When an alert fires, the exact GPS pin appears on the Map screen for your paired user.',
    ),
    _Slide(
      emoji: '✅',
      title: 'YOU\'RE\nREADY.',
      subtitle:
          'Add emergency contacts in the Contacts tab. Use the Debug tab to test alerts without hardware.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _buildSlide(_slides[i]),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _page ? SL.lime : SL.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: SL.lime,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _page == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SL.bg,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_page < _slides.length - 1) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: widget.onComplete,
                      child: const Center(
                        child: Text(
                          'Skip',
                          style: TextStyle(fontSize: 13, color: SL.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_Slide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          const Spacer(),
          Text(slide.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 22),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: SL.white,
              height: 0.95,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: SL.grey,
              height: 1.6,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  const _Slide(
      {required this.emoji, required this.title, required this.subtitle});
}
