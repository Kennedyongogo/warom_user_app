import 'package:edams_mobile/screens/Site%20visits/site_visits_list.dart';
import 'package:edams_mobile/screens/applications/track_application_page.dart';
import 'package:edams_mobile/screens/landing/landing_page.dart';
import 'package:edams_mobile/screens/verify/verify_permit_page.dart';
import 'package:edams_mobile/widgets/navigation/edams_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../profile/profile_screen.dart';
import '../auth/login_page.dart';
import '../../utils/utils.dart';
import '../Illegal%20Development%20Report/illegal_reports_page.dart';

class EDAMSDashboard extends StatefulWidget {
  const EDAMSDashboard({super.key});

  @override
  State<EDAMSDashboard> createState() => _EDAMSDashboardState();
}

class _EDAMSDashboardState extends State<EDAMSDashboard> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String userName = '';
  String userEmail = '';
  String userType = '';

  List<Widget> get _pages => [
        HomePage(
          userName: userName,
          userType: userType,
          userEmail: userEmail,
          onNavigateTab: _onItemTapped,
        ),
        const TrackApplicationPage(),
        const VerifyPermitPage(),
        const IllegalReportsPage(),
        const SiteVisitsListPage(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user info when dependencies change (e.g., after login)
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      var token = await _secureStorage.read(key: "edams_jwt");
      if (token == null || token.isEmpty) {
        // No token, redirect to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
        return;
      }

      var decoded = parseJwt(token);
      if (decoded['error'] != null) {
        // Invalid token, redirect to login
        await _secureStorage.delete(key: 'edams_jwt');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
        return;
      }

      // Token is valid, set user info
      if (mounted) {
        setState(() {
          userName = decoded["name"] ?? 'User';
          userEmail = decoded["email"] ?? '';
          userType = decoded["role"] ?? 'citizen';
        });
      }
    } catch (e) {
      // Error parsing token, redirect to login
      await _secureStorage.delete(key: 'edams_jwt');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    final max = _pages.length - 1;
    if (index < 0 || index > max) return;
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  static const _navItems = [
    EdamsNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
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
      icon: Icons.report_problem_outlined,
      activeIcon: Icons.report_problem_rounded,
      label: 'Illegal',
    ),
    EdamsNavItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'Visits',
    ),
    EdamsNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final index = _selectedIndex.clamp(0, pages.length - 1);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) {
          setState(() {
            _selectedIndex = i;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : EdamsBottomNav(
              currentIndex: index,
              items: _navItems,
              onTap: _onItemTapped,
            ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String userName;
  final String userType;
  final String userEmail;
  final ValueChanged<int>? onNavigateTab;

  const HomePage({
    super.key,
    required this.userName,
    required this.userType,
    required this.userEmail,
    this.onNavigateTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pendingSiteVisits = 0;
  int _completedSiteVisits = 0;
  bool _isLoadingStats = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSiteVisitStats();
  }

  Future<void> _refreshDashboard() async {
    await _loadSiteVisitStats();
  }

  Future<void> _loadSiteVisitStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      final token = await _secureStorage.read(key: "edams_jwt");
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${getUrl()}site-visits'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<Map<String, dynamic>> siteVisits = [];

          // Use the exact same logic as site_visits_list.dart
          if (responseData['data'] is List) {
            siteVisits = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData['data'] is Map &&
              responseData['data']['data'] is List) {
            siteVisits =
                List<Map<String, dynamic>>.from(responseData['data']['data']);
          }

          // Get current user ID from token
          final decoded = parseJwt(token);
          final userId = decoded['id'];

          // Count pending and completed - only for this user's site visits
          int pending = 0;
          int completed = 0;

          for (var visit in siteVisits) {
            final adminUserId = visit['AdminUserID']?.toString();

            // Only count visits assigned to this user
            if (adminUserId == userId) {
              bool isCompleted = visit['IsSiteVisitCompleted'] ?? false;
              if (isCompleted) {
                completed++;
              } else {
                pending++;
              }
            }
          }

          if (mounted) {
            setState(() {
              _pendingSiteVisits = pending;
              _completedSiteVisits = completed;
            });
          }
        } else {}
      } else {
        debugPrint('Site visit stats fetch failed: ${response.statusCode}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    // Clear stored token
    const secureStorage = FlutterSecureStorage();
    await secureStorage.delete(key: 'edams_jwt');

    // Navigate back to landing page
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

  String get _firstName {
    final name = widget.userName.trim();
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: RefreshIndicator(
        color: green,
        onRefresh: _refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: green,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Nyamira EDAMS',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Log out',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _handleLogout,
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WelcomeBanner(
                    greeting: _greeting,
                    firstName: _firstName,
                  ),
                  const SizedBox(height: 22),
                  const _SectionLabel(title: 'Site visits'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Pending',
                          count: _pendingSiteVisits,
                          loading: _isLoadingStats,
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFB54708),
                          soft: const Color(0xFFFFF4E5),
                          onTap: () => _openVisits(filter: 'pending'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          label: 'Completed',
                          count: _completedSiteVisits,
                          loading: _isLoadingStats,
                          icon: Icons.check_circle_rounded,
                          color: green,
                          soft: const Color(0xFFE8F5E9),
                          onTap: () => _openVisits(filter: 'completed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(title: 'Quick actions'),
                  const SizedBox(height: 12),
                  _ActionTile(
                    title: 'Verify a permit',
                    subtitle: 'Scan a permit QR code to confirm it is genuine',
                    icon: Icons.qr_code_scanner_rounded,
                    color: const Color(0xFF8A5A00),
                    soft: const Color(0xFFFFF4D6),
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    title: 'Illegal reports',
                    subtitle: 'Review and follow up on submissions',
                    icon: Icons.report_problem_rounded,
                    color: const Color(0xFFB42318),
                    soft: const Color(0xFFFEE4E2),
                    onTap: () => widget.onNavigateTab?.call(3),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    title: 'Site visits',
                    subtitle: 'Open your assigned visit list',
                    icon: Icons.map_rounded,
                    color: const Color(0xFF2F5F2F),
                    soft: const Color(0xFFE6EFE6),
                    onTap: () => widget.onNavigateTab?.call(4),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    title: 'Track application',
                    subtitle: 'Look up a code like NYM-2026-00042',
                    icon: Icons.travel_explore_rounded,
                    color: green,
                    soft: const Color(0xFFE8F5E9),
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVisits({required String filter}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiteVisitsListPage(initialFilter: filter),
      ),
    );
    if (result == true && mounted) {
      _loadSiteVisitStats();
    }
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String greeting;
  final String firstName;

  const _WelcomeBanner({
    required this.greeting,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D4F14), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here’s what’s on your desk today.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Color(0xFFF2C94C),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B3A2A),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  final bool loading;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.count,
    required this.loading,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3A2A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
