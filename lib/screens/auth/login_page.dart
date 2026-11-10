import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:email_validator/email_validator.dart';
import '../../utils/utils.dart';
import '../../widgets/form_fields/custom_text_field.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/dialogs/forgot_password_dialog.dart';
import '../dashboard/dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  final dynamic userType;

  const LoginPage({super.key, this.userType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!EmailValidator.validate(_emailController.text.trim())) {
      _showMessage('Please enter a valid email address!', Colors.red);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${getUrl()}admin-users/login"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'Email': _emailController.text.trim(),
          'Password': _passwordController.text,
          'Type': 'Mobile',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']?['token'];
        if (token == null) {
          _showMessage('Login succeeded but token missing', Colors.red);
          return;
        }
        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(key: 'edams_jwt', value: token);

        if (mounted) {
          _showMessage('Welcome back!', const Color(0xFF2E7D32));
          // Clear landing / guest stack so Illegal tab back doesn't return home.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EDAMSDashboard()),
            (route) => false,
          );
        }
      } else {
        _showMessage(data['message'] ?? 'Login failed', Colors.red);
      }
    } catch (e) {
      _showMessage('An error occurred. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (context) => const ForgotPasswordDialog(),
    );
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      // Pad for keyboard ourselves so the page stays fully scrollable
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        // Keyboard height as bottom padding → scroll fields above it
                        padding: EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          24 + keyboardInset,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(0, constraints.maxHeight - 48),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.location_city,
                                            size: 48,
                                            color: Color(0xFF2E7D32),
                                          ),
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
                                        'Electronic Development Asset Management System',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              Transform.translate(
                                offset: Offset(
                                    0, 20 * (1 - _fadeAnimation.value)),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text(
                                          'Welcome Back',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Sign in to your account',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        CustomTextField(
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          label: 'Email',
                                          hint: 'Enter your email',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction:
                                              TextInputAction.next,
                                          scrollPadding:
                                              const EdgeInsets.only(
                                            bottom: 140,
                                          ),
                                          prefixIcon: const Icon(Icons.email),
                                          onFieldSubmitted: (_) {
                                            FocusScope.of(context)
                                                .requestFocus(_passwordFocus);
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        CustomTextField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          prefixIcon: const Icon(Icons.lock),
                                          obscureText: _obscurePassword,
                                          textInputAction:
                                              TextInputAction.done,
                                          scrollPadding:
                                              const EdgeInsets.only(
                                            bottom: 120,
                                          ),
                                          onFieldSubmitted: (_) =>
                                              _handleLogin(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed:
                                                _showForgotPasswordDialog,
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        CustomButton(
                                          text: 'Sign In',
                                          onPressed: _isLoading
                                              ? null
                                              : _handleLogin,
                                          isLoading: _isLoading,
                                          width: double.infinity,
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
