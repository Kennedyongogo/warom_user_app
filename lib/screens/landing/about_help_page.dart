import 'package:flutter/material.dart';

class AboutHelpPage extends StatelessWidget {
  const AboutHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About EDAMS'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset + 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.location_city,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nyamira EDAMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Electronic Development Application Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // About Section
            _buildSection(
              'About EDAMS',
              Icons.info_outline,
              const Color(0xFF2E7D32),
              [
                'EDAMS is a comprehensive digital platform designed to streamline development application management, permit processing, and regulatory compliance for Nyamira County.',
                'Our system modernizes traditional paper-based development application processes, making them more efficient, transparent, and accessible to citizens and government officials.',
                'Built with cutting-edge technology, EDAMS ensures data security, real-time updates, and seamless user experience across all devices.',
              ],
            ),

            // Features Section
            _buildSection(
              'Key Features',
              Icons.star_outline,
              const Color(0xFF4CAF50),
              [
                'Development Application Management - Submit and track development permits digitally',
                'Land Use Planning - Comprehensive tracking of development projects and zoning',
                'Real-time Updates - Instant notifications on application status',
                'Secure Platform - Enterprise-grade security and data protection',
                'Mobile Access - Full functionality on smartphones and tablets',
                'Payment Integration - Secure online payment processing',
                'Map Integration - Visual representation of development areas',
                'Reporting Tools - Comprehensive analytics and reporting',
              ],
            ),

            // How It Works Section
            _buildSection(
              'How It Works',
              Icons.help_outline,
              const Color(0xFF2196F3),
              [
                '1. Create Account - Sign up with your email and personal details',
                '2. Submit Applications - Fill out digital forms and upload documents',
                '3. Track Progress - Monitor application status in real-time',
                '4. Make Payments - Pay fees securely through integrated payment system',
                '5. Receive Updates - Get notifications on approvals, rejections, or additional requirements',
                '6. Access Documents - Download approved permits and certificates',
              ],
            ),

            // Help & Support Section
            _buildSection(
              'Help & Support',
              Icons.support_agent,
              const Color(0xFF9C27B0),
              [
                'User Guide - Comprehensive documentation for all features',
                'Video Tutorials - Step-by-step video guides',
                'FAQ - Frequently asked questions and answers',
                'Contact Support - Direct communication with our support team',
                'Live Chat - Real-time assistance during business hours',
                'Email Support - Send detailed queries via email',
              ],
            ),

            // Contact Information Section
            _buildSection(
              'Contact Information',
              Icons.contact_phone,
              const Color(0xFFFF9800),
              [
                'Nyamira County Government',
                'Address: Nyamira, Kenya',
                'Phone: +254 XXX XXX XXX',
                'Email: edams@nyamira.go.ke',
                'Website: www.nyamira.go.ke',
                'Business Hours: Monday - Friday, 8:00 AM - 5:00 PM',
              ],
            ),

            // Privacy & Terms Section
            _buildSection(
              'Privacy & Terms',
              Icons.privacy_tip_outlined,
              const Color(0xFF607D8B),
              [
                'Data Protection - Your personal information is securely protected',
                'Privacy Policy - We respect your privacy and handle data responsibly',
                'Terms of Service - Clear guidelines on system usage',
                'Data Retention - Information is retained as per government regulations',
                'Access Control - Role-based access ensures data security',
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<String> items) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
