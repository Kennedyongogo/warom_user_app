import 'package:edams_mobile/screens/applications/track_application_page.dart';
import 'package:edams_mobile/screens/auth/login_page.dart';
import 'package:edams_mobile/screens/verify/verify_permit_page.dart';
import 'package:edams_mobile/widgets/navigation/edams_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'welcome_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Getter so hot reload always picks up new tabs (field initializers keep stale State).
  List<Widget> get _pages => const [
        WelcomePage(),
        TrackApplicationPage(),
        VerifyPermitPage(),
        LoginPage(),
      ];

  static const _navItems = [
    EdamsNavItem(
      icon: Icons.report_problem_outlined,
      activeIcon: Icons.report_problem_rounded,
      label: 'Report',
    ),
    EdamsNavItem(
      icon: Icons.travel_explore_outlined,
      activeIcon: Icons.travel_explore_rounded,
      label: 'Track',
    ),
    EdamsNavItem(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner_rounded,
      label: 'Verify',
    ),
    EdamsNavItem(
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings_rounded,
      label: 'Admin',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final pages = _pages;
    final index = _currentIndex.clamp(0, pages.length - 1);

    if (index != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = index);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : EdamsBottomNav(
              currentIndex: index,
              items: _navItems,
              onTap: (i) {
                if (i < 0 || i >= pages.length) return;
                setState(() => _currentIndex = i);
              },
            ),
    );
  }
}
