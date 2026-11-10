import 'package:edams_mobile/screens/auth/login_page.dart';
import 'package:flutter/material.dart';

class ChooseProfession extends StatefulWidget {
  const ChooseProfession({super.key});

  @override
  State<ChooseProfession> createState() => _ChooseProfessionState();
}

class _ChooseProfessionState extends State<ChooseProfession>
    with TickerProviderStateMixin {
  String? userType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleProfessionSelection(String userType) {
    setState(() {
      userType = userType;
    });

    // Navigate after a short delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginPage(
                    userType: userType,
                  )),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D4F14),
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Enhanced Logo Section with Animation
                          Transform.scale(
                            scale: _fadeAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_city_rounded,
                                      size: 48,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Nyamira EDAMS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Electronic Development Asset\nManagement System',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.3,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Enhanced Selection Card
                          Transform.translate(
                            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Welcome Header with Enhanced Design
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2E7D32),
                                          Color(0xFF4CAF50),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2E7D32)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.person_search_rounded,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Welcome to EDAMS',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Select your profession to continue",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Profession Selection Cards with Enhanced Design
                                  _buildProfessionCard(
                                    title: "Admin User",
                                    subtitle: "System Administrator",
                                    icon: Icons.admin_panel_settings_rounded,
                                    description:
                                        "Manage applications, users, and system settings",
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2E7D32),
                                        Color(0xFF4CAF50)
                                      ],
                                    ),
                                    onTap: () => _handleProfessionSelection(
                                        "Admin User"),
                                  ),
                                  // const SizedBox(height: 12),
                                  // _buildProfessionCard(
                                  //   title: "Public User",
                                  //   subtitle: "Citizen/Developer",
                                  //   icon: Icons.person_rounded,
                                  //   description:
                                  //       "Submit applications and track progress",
                                  //   gradient: const LinearGradient(
                                  //     colors: [
                                  //       Color(0xFF1976D2),
                                  //       Color(0xFF42A5F5)
                                  //     ],
                                  //   ),
                                  //   onTap: () => _handleProfessionSelection(
                                  //       "Public User"),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String description,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final isSelected = userType == title;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected ? gradient : null,
              color: isSelected ? null : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.grey.withValues(alpha: 0.2),
                width: isSelected ? 0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : gradient.colors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : gradient.colors.first,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
