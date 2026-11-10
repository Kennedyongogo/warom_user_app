import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:http/http.dart';
import '../../utils/utils.dart';
import '../form_fields/custom_text_field.dart';
import '../buttons/custom_button.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  // ==================== ALL VARIABLES ====================
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // State Variables
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  // ==================== ALL FUNCTIONS ====================
  // Lifecycle Methods
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Authentication Methods
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = 'Please enter your email address';
        _isSuccess = false;
      });
      return;
    }

    if (!EmailValidator.validate(_emailController.text.trim())) {
      setState(() {
        _message = 'Please enter a valid email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await post(
        Uri.parse("${getUrl()}admin-users/forgot-password"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'Email': _emailController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isSuccess = true;
          _message = 'Temporary password sent to your email!';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context);
        });
      } else {
        setState(() {
          _isSuccess = false;
          _message = data['message'] ?? 'Failed to send reset email';
        });
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // UI Build Method
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),

              // Header
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Enter your email to reset your password.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Email field
              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _isSuccess ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Submit',
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
