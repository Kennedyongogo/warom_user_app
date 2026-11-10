import 'dart:async';

import 'package:edams_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:edams_mobile/screens/landing/main_navigation.dart';
import 'package:edams_mobile/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'about_help_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _Feature {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<(IconData, String)> chips;

  const _Feature({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.chips,
  });
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  static const _deep = Color(0xFF0B3D2E);
  static const _greenDark = Color(0xFF1B6E54);
  static const _green = Color(0xFF289C75);
  static const _gold = Color(0xFFF2C94C);
  static const _mint = Color(0xFF9FE0C4);

  final PageController _pageController = PageController();
  final storage = const FlutterSecureStorage();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);
  Timer? _autoplay;
  int _currentPage = 0;

  static const _features = [
    _Feature(
      eyebrow: 'Apply online',
      title: 'Development applications, fully digital',
      description: 'Submit plans, upload documents and pay county fees from your phone, with no queues.',
      icon: Icons.description_rounded,
      accent: _mint,
      chips: [(Icons.cloud_upload_rounded, 'Upload plans'), (Icons.payments_rounded, 'Pay fees')],
    ),
    _Feature(
      eyebrow: 'Real-time tracking',
      title: 'Know where your application is',
      description: 'Follow every stage from vetting to the committee decision, and get notified as it moves.',
      icon: Icons.track_changes_rounded,
      accent: _gold,
      chips: [(Icons.notifications_active_rounded, 'Instant updates'), (Icons.timeline_rounded, 'Every stage')],
    ),
    _Feature(
      eyebrow: 'Permit verification',
      title: 'Is that permit genuine? Scan to know',
      description: 'Scan the QR code on any Nyamira permit to confirm it was issued by the County. No account needed.',
      icon: Icons.qr_code_scanner_rounded,
      accent: _gold,
      chips: [(Icons.verified_rounded, 'Authentic check'), (Icons.bolt_rounded, 'In seconds')],
    ),
    _Feature(
      eyebrow: 'Secure & reliable',
      title: 'Your data, protected',
      description: 'Encrypted sign-in, county-grade security and backed-up records you can rely on.',
      icon: Icons.shield_rounded,
      accent: _mint,
      chips: [(Icons.lock_rounded, 'Encrypted'), (Icons.backup_rounded, 'Backed up')],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _float.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _autoplay?.cancel();
    _autoplay = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _features.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  void _goTo(int page) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    _startAutoplay();
  }

  Future<void> fetchUserInfo() async {
    final token = await storage.read(key: 'edams_jwt');
    if (!mounted) return;
    if (token != null) {
      final decoded = parseJwt(token);
      debugPrint(decoded.toString());
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EDAMSDashboard()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final feature = _features[_currentPage];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _deep,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_deep, _greenDark, _green],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final t = _float.value;
                return Stack(
                  children: [
                    _Glow(top: -80 + 20 * t, right: -70, size: 260, color: feature.accent.withValues(alpha: 0.22)),
                    _Glow(bottom: 120 - 24 * t, left: -90, size: 240, color: _gold.withValues(alpha: 0.14)),
                  ],
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_rounded, color: _greenDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nyamira eDAMS',
                                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'County Government of Nyamira',
                                style: TextStyle(color: _gold, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: _currentPage == _features.length - 1 ? 0 : 1,
                          child: TextButton(
                            onPressed: _currentPage == _features.length - 1 ? null : () => _goTo(_features.length - 1),
                            style: TextButton.styleFrom(foregroundColor: Colors.white70),
                            child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollStartNotification>(
                      onNotification: (n) {
                        if (n.dragDetails != null) _startAutoplay();
                        return false;
                      },
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        itemCount: _features.length,
                        itemBuilder: (context, index) => _FeatureSlide(
                          feature: _features[index],
                          float: _float,
                          active: index == _currentPage,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_features.length, (i) {
                      final on = i == _currentPage;
                      return GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: on ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: on ? _gold : Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: fetchUserInfo,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _greenDark,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Get started', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _GlassAction(
                            icon: Icons.info_outline_rounded,
                            label: 'Learn more',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AboutHelpPage()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSlide extends StatelessWidget {
  final _Feature feature;
  final Animation<double> float;
  final bool active;

  const _FeatureSlide({required this.feature, required this.float, required this.active});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final art = (constraints.maxHeight * 0.42).clamp(140.0, 250.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: art + 60,
                height: art,
                child: AnimatedBuilder(
                  animation: float,
                  builder: (context, _) {
                    final t = float.value;
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 3; i >= 1; i--)
                          Container(
                            width: art * (0.42 + i * 0.19),
                            height: art * (0.42 + i * 0.19),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06 + 0.03 * (3 - i))),
                              color: Colors.white.withValues(alpha: 0.025 * (4 - i)),
                            ),
                          ),
                        Transform.translate(
                          offset: Offset(0, -6 * t),
                          child: AnimatedScale(
                            scale: active ? 1 : 0.86,
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: art * 0.46,
                              height: art * 0.46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(art * 0.14),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, feature.accent.withValues(alpha: 0.55)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 16)),
                                  BoxShadow(color: feature.accent.withValues(alpha: 0.35), blurRadius: 40),
                                ],
                              ),
                              child: Icon(feature.icon, size: art * 0.24, color: const Color(0xFF1B6E54)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: art * 0.16 + 8 * t,
                          child: _FloatingChip(icon: feature.chips[0].$1, label: feature.chips[0].$2, accent: feature.accent),
                        ),
                        Positioned(
                          right: 0,
                          bottom: art * 0.14 + 8 * (1 - t),
                          child: _FloatingChip(icon: feature.chips[1].$1, label: feature.chips[1].$2, accent: feature.accent),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 26),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: active ? 1 : 0.4,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: feature.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: feature.accent.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        feature.eyebrow.toUpperCase(),
                        style: TextStyle(color: feature.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      feature.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 14.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _FloatingChip({required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFE9F5EF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: const Color(0xFF1B6E54)),
          ),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Color(0xFF10291F), fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _GlassAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double? top, left, right, bottom;
  final double size;
  final Color color;

  const _Glow({this.top, this.left, this.right, this.bottom, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      ),
    );
  }
}
