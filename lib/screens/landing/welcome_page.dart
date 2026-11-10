import 'package:edams_mobile/screens/Illegal%20Development%20Report/illegal_development_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Guest "Report" tab: invites the public to report unauthorized development.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  static const _deep = Color(0xFF0B3D2E);
  static const _greenDark = Color(0xFF1B6E54);
  static const _green = Color(0xFF289C75);
  static const _gold = Color(0xFFF2C94C);
  static const _ink = Color(0xFF10291F);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  void _navigateToReport() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IllegalDevelopmentReport()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));

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
                    _Glow(top: -70 + 18 * t, right: -80, size: 260, color: _gold.withValues(alpha: 0.18)),
                    _Glow(bottom: 60 - 20 * t, left: -100, size: 260, color: const Color(0xFF9FE0C4).withValues(alpha: 0.16)),
                  ],
                );
              },
            ),
            SafeArea(
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _brandRow(),
                              const SizedBox(height: 18),
                              _illustration(),
                              const SizedBox(height: 22),
                              _copy(),
                              const SizedBox(height: 20),
                              _steps(),
                              const SizedBox(height: 22),
                              _cta(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandRow() {
    return Row(
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
              Text('Nyamira eDAMS', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              Text(
                'County Government of Nyamira',
                style: TextStyle(color: _gold, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _illustration() {
    const art = 210.0;
    return SizedBox(
      width: art + 70,
      height: art,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final t = _float.value;
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
                child: Container(
                  width: art * 0.46,
                  height: art * 0.46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(art * 0.14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, _gold.withValues(alpha: 0.55)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 16)),
                      BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 40),
                    ],
                  ),
                  child: const Icon(Icons.report_problem_rounded, size: art * 0.24, color: _greenDark),
                ),
              ),
              Positioned(
                left: 0,
                top: art * 0.14 + 8 * t,
                child: const _FloatingChip(icon: Icons.photo_camera_rounded, label: 'Snap a photo'),
              ),
              Positioned(
                right: 0,
                bottom: art * 0.12 + 8 * (1 - t),
                child: const _FloatingChip(icon: Icons.location_on_rounded, label: 'Pin location'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _copy() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _gold.withValues(alpha: 0.45)),
          ),
          child: const Text(
            'COMMUNITY WATCH',
            style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Report unauthorized development',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'Seen construction without a permit near you? Tell the County in under a minute. No account needed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 14.5, height: 1.5),
        ),
      ],
    );
  }

  Widget _steps() {
    const steps = [
      (Icons.photo_camera_rounded, 'Photo'),
      (Icons.my_location_rounded, 'Location'),
      (Icons.send_rounded, 'Submit'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: i == steps.length - 1 ? _gold : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(steps[i].$1, size: 20, color: i == steps.length - 1 ? _ink : _greenDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${i + 1}. ${steps[i].$2}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1)
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.45)),
          ],
        ],
      ),
    );
  }

  Widget _cta() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _navigateToReport,
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
                Icon(Icons.report_problem_rounded, size: 20),
                SizedBox(width: 8),
                Text('Report development', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              'Your report goes straight to County planning officers',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FloatingChip({required this.icon, required this.label});

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
