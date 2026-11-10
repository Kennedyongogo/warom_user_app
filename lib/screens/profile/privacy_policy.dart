import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      size: 48,
                      color: getColor('primary'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nyamira County Electronic Development Application Management System',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              'Introduction',
              Icons.info_outline,
              'This Privacy Policy explains how Nyamira County collects, uses, and protects your personal information when you use the EDAMS Mobile Application. By using our app, you agree to the collection and use of information in accordance with this policy.',
            ),

            // Information We Collect
            _buildSection(
              'Information We Collect',
              Icons.data_usage,
              'We collect several types of information to provide and improve our services:',
              children: [
                _buildSubSection('Personal Information', [
                  'Name and contact details (email, phone number)',
                  'National ID number for verification',
                  'Physical address and location data',
                  'Profile information and preferences',
                ]),
                _buildSubSection('Application Data', [
                  'Development application details',
                  'Property information and documents',
                  'Payment records and transaction history',
                  'Site visit reports and photos',
                ]),
                _buildSubSection('Technical Information', [
                  'Device information and operating system',
                  'App usage statistics and performance data',
                  'IP address and network information',
                  'Crash reports and error logs',
                ]),
                _buildSubSection('Location Data', [
                  'GPS coordinates for site visits',
                  'Location-based services data',
                  'Geographic information for applications',
                ]),
              ],
            ),

            // How We Use Information
            _buildSection(
              'How We Use Your Information',
              Icons.how_to_reg,
              'We use the collected information for the following purposes:',
              children: [
                _buildSubSection('Service Provision', [
                  'Process development applications',
                  'Manage permits and approvals',
                  'Facilitate payments and transactions',
                  'Provide customer support',
                ]),
                _buildSubSection('Communication', [
                  'Send application status updates',
                  'Notify about important changes',
                  'Respond to inquiries and support requests',
                  'Send system notifications',
                ]),
                _buildSubSection('Improvement', [
                  'Analyze app performance and usage',
                  'Enhance user experience',
                  'Develop new features',
                  'Ensure system security',
                ]),
                _buildSubSection('Compliance', [
                  'Meet legal and regulatory requirements',
                  'Maintain audit trails',
                  'Prevent fraud and abuse',
                  'Enforce terms of service',
                ]),
              ],
            ),

            // Data Security
            _buildSection(
              'Data Security',
              Icons.security,
              'We implement appropriate security measures to protect your personal information:',
              children: [
                _buildSubSection('Security Measures', [
                  'Encryption of data in transit and at rest',
                  'Secure authentication and access controls',
                  'Regular security audits and updates',
                  'Employee training on data protection',
                  'Secure backup and recovery procedures',
                  'Incident response and breach notification',
                ]),
              ],
            ),

            // Data Sharing
            _buildSection(
              'Data Sharing and Disclosure',
              Icons.share,
              'We may share your information in the following circumstances:',
              children: [
                _buildSubSection('Sharing Circumstances', [
                  'With government agencies as required by law',
                  'With service providers who assist in app operations',
                  'When required by court order or legal process',
                  'To protect our rights and prevent fraud',
                  'With your explicit consent for specific purposes',
                  'In case of business transfers or mergers',
                ]),
              ],
            ),

            // Your Rights
            _buildSection(
              'Your Rights',
              Icons.account_balance,
              'You have the following rights regarding your personal information:',
              children: [
                _buildSubSection('User Rights', [
                  'Access your personal data',
                  'Request correction of inaccurate information',
                  'Request deletion of your data',
                  'Object to processing of your data',
                  'Request data portability',
                  'Withdraw consent at any time',
                  'File complaints with supervisory authorities',
                ]),
              ],
            ),

            // Data Retention
            _buildSection(
              'Data Retention',
              Icons.schedule,
              'We retain your personal information for as long as necessary to:',
              children: [
                _buildSubSection('Retention Purposes', [
                  'Provide our services to you',
                  'Comply with legal obligations',
                  'Resolve disputes and enforce agreements',
                  'Maintain accurate records for audit purposes',
                  'Support ongoing application processes',
                ]),
              ],
            ),

            // Cookies and Tracking
            _buildSection(
              'Cookies and Tracking Technologies',
              Icons.cookie,
              'Our app may use cookies and similar technologies to:',
              children: [
                _buildSubSection('Technology Uses', [
                  'Remember your preferences and settings',
                  'Analyze app usage and performance',
                  'Provide personalized content',
                  'Improve user experience',
                  'Ensure app security and functionality',
                ]),
              ],
            ),

            // Third-Party Services
            _buildSection(
              'Third-Party Services',
              Icons.link,
              'Our app may integrate with third-party services for:',
              children: [
                _buildSubSection('Service Types', [
                  'Payment processing',
                  'Map and location services',
                  'Cloud storage and backup',
                  'Analytics and monitoring',
                  'Communication services',
                ]),
              ],
            ),

            // Children's Privacy
            _buildSection(
              'Children\'s Privacy',
              Icons.child_care,
              'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
            ),

            // Changes to Policy
            _buildSection(
              'Changes to This Privacy Policy',
              Icons.update,
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),

            // Contact Information
            _buildSection(
              'Contact Information',
              Icons.contact_phone,
              'If you have any questions about this Privacy Policy or our data practices, please contact us:',
              children: [
                _buildSubSection('Contact Details', [
                  'Email: privacy@nyamira.go.ke',
                  'Phone: +254 20 123 4567',
                  'Address: Nyamira County Government, Nyamira Town',
                  'Office Hours: Monday - Friday, 8:00 AM - 5:00 PM',
                ]),
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 32,
                      color: getColor('primary'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your Privacy Matters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy reflects our dedication to transparency and compliance with applicable data protection laws.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content,
      {List<Widget>? children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: getColor('primary'), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            if (children != null) ...[
              const SizedBox(height: 12),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
