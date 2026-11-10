import 'package:edams_mobile/screens/auth/login_page.dart';
import 'package:edams_mobile/widgets/buttons/custom_button.dart';
import 'package:edams_mobile/widgets/form_fields/custom_text_field.dart';
import 'package:edams_mobile/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('New passwords do not match!', Colors.red);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showMessage('New password must be at least 6 characters!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user ID from stored token
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'edams_jwt');

      if (token == null) {
        _showMessage('Please login again', Colors.red);
        return;
      }

      // Parse token to get user ID
      final tokenData = parseJwt(token);
      final userId = tokenData['id'] ?? tokenData['user_id'];

      if (userId == null) {
        _showMessage('Invalid user session', Colors.red);
        return;
      }

      // Call API to update password
      final response = await httpPut(
        'users/$userId',
        {
          'Password': _newPasswordController.text,
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          _showMessage('Password changed successfully! Please login again.',
              const Color(0xFF2E7D32));

          // Clear stored token
          await secureStorage.delete(key: 'edams_jwt');

          // Navigate to login page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
      } else {
        if (mounted) {
          _showMessage(
              response['message'] ?? 'Failed to change password', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error changing password: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 48,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const SizedBox(height: 32),

                        // Old Password Field
                        CustomTextField(
                          controller: _oldPasswordController,
                          label: 'Current Password',
                          hint: 'Enter your current password',
                          obscureText: _obscureOldPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureOldPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureOldPassword = !_obscureOldPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // New Password Field
                        CustomTextField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          hint: 'Enter your new password',
                          obscureText: _obscureNewPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          hint: 'Confirm your new password',
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Change Password Button
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: _isLoading
                                ? 'Changing Password...'
                                : 'Change Password',
                            onPressed: _isLoading ? null : _changePassword,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
