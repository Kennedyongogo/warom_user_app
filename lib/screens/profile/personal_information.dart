import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import '../../utils/utils.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String name = '';
  String email = '';
  String phone = '';
  String role = '';
  String position = '';
  String accessLevel = '';
  String departmentId = '';
  String directory = '';
  String signature = '';

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    fetchUserDetails();
  }

  Future<Message> fetchUserDetails() async {
    try {
      dynamic response;

      var token = await storage.read(key: "edams_jwt");

      response = await get(
        Uri.parse('${getUrl()}admin-users/me/profile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      var responseData = jsonDecode(response.body);

   
      if (mounted) {
        setState(() {
          name = responseData['Name'] ?? '';
          email = responseData['Email'] ?? '';
          phone = responseData['PhoneNumber'] ?? '';
          role = responseData['Role'] ?? '';
          departmentId =
              responseData['adminUser']?['DepartmentID']?.toString() ?? '';
          position = responseData['adminUser']?['Position'] ?? '';
          accessLevel = responseData['adminUser']?['AccessLevel'] ?? '';
          directory = responseData['adminUser']?['Directory'] ?? '';
          signature = responseData['adminUser']?['Signature'] ?? '';
        });
      }

  
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Message.fromJson(responseData);
      } else {
        return Message(
          data: null,
          message:
              responseData['message'] ?? "Server error! Contact administrator.",
          success: false,
        );
      }
    } catch (e) {
      return Message(
        data: null,
        message: "Connection failed! Check your internet connection. Error: $e",
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2E7D32),
            ),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: fetchUserDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 28),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildDetailsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name.isNotEmpty ? name : 'Loading...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email.isNotEmpty ? email : 'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.isNotEmpty ? role : 'Loading...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Personal Information',
            [
              _buildDetailItem(Icons.person, 'Full Name', name),
              _buildDetailItem(Icons.email, 'Email', email),
              _buildDetailItem(Icons.phone, 'Phone', phone),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Work Information',
            [
              _buildDetailItem(Icons.work, 'Position', position),
              _buildDetailItem(Icons.security, 'Access Level', accessLevel),
              _buildDetailItem(Icons.folder, 'Directory', directory),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final dynamic data;
  final String message;
  final bool success;

  Message({
    required this.data,
    required this.message,
    required this.success,
  });

  // Helper getter to check if operation was successful
  bool get isSuccess => success;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      data: json['data'],
      message: json['message'] ??
          (json['success']
              ? "Operation completed successfully"
              : "An error occurred"),
      success: json['success'] ?? false,
    );
  }
}
