import 'package:edams_mobile/screens/landing/about_help_page.dart';
import 'package:edams_mobile/screens/profile/change_password.dart';
import 'package:edams_mobile/screens/profile/personal_information.dart';
import 'package:edams_mobile/screens/profile/privacy_policy.dart';
import 'package:edams_mobile/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../landing/landing_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String userName = '';
  String userEmail = '';
  String userType = '';

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      var token = await _secureStorage.read(key: "edams_jwt");
      if (token != null) {
        var decoded = parseJwt(token);
        setState(() {
          userName = decoded["name"] ?? 'User';
          userEmail = decoded["email"] ?? '';
          userType = decoded["role"] ?? 'Public User';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'User';
        userEmail = 'user@email.com';
        userType = 'Public User';
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: getUserInfo,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   children: [
                      //     _buildProfileStat('Applications', '12'),
                      //     _buildProfileStat('Payments', '8'),
                      //     _buildProfileStat('Documents', '25'),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Options
            const Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              'Personal Information',
              Icons.person,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PersonalInformation()));
              },
            ),
            _buildProfileOption(
              'Change Password',
              Icons.lock,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangePassword()));
              },
            ),

            _buildProfileOption(
              'About EDAMS',
              Icons.info,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutHelpPage(),
                  ),
                );
              },
            ),

            _buildProfileOption(
              'Privacy Policy',
              Icons.privacy_tip,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _handleLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
