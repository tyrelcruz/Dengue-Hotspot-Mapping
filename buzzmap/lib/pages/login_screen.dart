import 'package:buzzmap/pages/otp_screen.dart';
import 'package:buzzmap/pages/register_screen.dart';
import 'package:buzzmap/pages/welcome_screen.dart';
import 'package:buzzmap/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/errors/flushbar.dart'; // Import the new AppFlushBar utility

//Share preferences for saving local instances
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  void _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': 'user',
        }),
      );

      print('🔐 Raw login response: ${response.body}');
      final responseData = jsonDecode(response.body);

      // Check if there is an error in the response
      if (responseData['status'] == 'error') {
        String errorMessage = responseData['message'] ?? 'Login failed';
        if (errorMessage.contains('Incorrect password')) {
          _showError('Incorrect email or password');
        } else {
          _showError(errorMessage);
        }
        return;
      }

      final token = responseData['accessToken']; // ✅ FIXED KEY
      final userRole =
          responseData['user']?['role']; // Assuming role is returned

      print('🔑 Token received: $token');

      if (response.statusCode == 200 &&
          token != null &&
          token is String &&
          token.isNotEmpty) {
        // Check for the role
        if (userRole == 'admin') {
          _showError('Admins are not allowed to login');
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        print('✅ Token saved to SharedPreferences');

        // Save username to SharedPreferences
        final username = responseData['user']?['username'] ?? '';
        await prefs.setString('username', username);
        print('👤 Username saved to SharedPreferences: $username');

        // Save user ID to SharedPreferences
        final userId = responseData['user']?['_id'] ?? '';
        if (userId.isNotEmpty) {
          await prefs.setString('userId', userId);
          print('👤 User ID saved to SharedPreferences: $userId');
        }

        await _saveCredentials();

        if (responseData['user']?['verified'] == false) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(email: _emailController.text),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        print('❌ Token not saved or missing in response');
        _showError('Login failed: No valid token received');
      }
    } catch (e) {
      print('❌ Login error: $e');
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    // Using the new AppFlushBar utility instead of the direct showCustomizeFlushbar
    AppFlushBar.showError(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D4C5E),
      body: Column(
        children: [
          const SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WelcomeScreen()),
                        );
                      },
                    ),
                    SvgPicture.asset(
                      'assets/icons/logo_darkbg.svg',
                      height: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "WELCOME BACK!",
                    style: TextStyle(
                      fontFamily: 'Koulen',
                      fontSize: 60,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "Login to stay informed and help prevent\n dengue outbreaks in your community.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter-Regular',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(50),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Email",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          filled: true,
                          fillColor: Color(0xFFDBEBF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      const Text("Password",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Color(0xFF1D4C5E),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Color(0xFFDBEBF3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipOval(
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  fillColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.blue;
                                    }
                                    return const Color.fromARGB(
                                        0, 255, 255, 255);
                                  }),
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                      color: Color(0xFF1D4C5E), width: 2),
                                ),
                              ),
                              const Text(
                                "Remember Me",
                                style: TextStyle(
                                  fontFamily: 'Inter-Regular',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              // Show dialog to enter email
                              final TextEditingController
                                  forgotEmailController =
                                  TextEditingController();
                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    insetPadding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 24),
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        20, 18, 20, 8),
                                    title: const Text('Forgot Password',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    content: SizedBox(
                                      width: 340,
                                      child: TextField(
                                        controller: forgotEmailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: const InputDecoration(
                                          labelText: 'Enter your email',
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                              context,
                                              forgotEmailController.text
                                                  .trim());
                                        },
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result != null && result.isNotEmpty) {
                                // Send forgot password request
                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                        '${Config.baseUrl}/api/v1/auth/forgot-password'),
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({'email': result}),
                                  );
                                  final data = jsonDecode(response.body);
                                  if (response.statusCode == 200 &&
                                      data['status'] == 'Success') {
                                    AppFlushBar.showSuccess(
                                      context,
                                      message: data['message'] ??
                                          'Password reset email sent!',
                                    );
                                    // Show dialog to enter OTP and new password
                                    final TextEditingController otpController =
                                        TextEditingController();
                                    final TextEditingController
                                        newPasswordController =
                                        TextEditingController();
                                    final TextEditingController
                                        confirmPasswordController =
                                        TextEditingController();
                                    final resetResult = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          insetPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 30, vertical: 24),
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  20, 18, 20, 8),
                                          title: const Text('Reset Password',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          content: SizedBox(
                                            width: 340,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: otpController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Enter OTP',
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller:
                                                      newPasswordController,
                                                  obscureText: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'New Password',
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                TextField(
                                                  controller:
                                                      confirmPasswordController,
                                                  obscureText: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Confirm Password',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final otp =
                                                    otpController.text.trim();
                                                final newPassword =
                                                    newPasswordController.text;
                                                final confirmPassword =
                                                    confirmPasswordController
                                                        .text;
                                                if (otp.isEmpty ||
                                                    newPassword.isEmpty ||
                                                    confirmPassword.isEmpty) {
                                                  AppFlushBar.showError(context,
                                                      message:
                                                          'All fields are required.');
                                                  return;
                                                }
                                                if (newPassword !=
                                                    confirmPassword) {
                                                  AppFlushBar.showError(context,
                                                      message:
                                                          'Passwords do not match.');
                                                  return;
                                                }
                                                // Verify OTP and reset password
                                                try {
                                                  final verifyResponse =
                                                      await http.post(
                                                    Uri.parse(
                                                        '${Config.baseUrl}/api/v1/otp/verify'),
                                                    headers: {
                                                      'Content-Type':
                                                          'application/json'
                                                    },
                                                    body: jsonEncode({
                                                      'email': result,
                                                      'otp': otp,
                                                      'purpose':
                                                          'password-reset',
                                                    }),
                                                  );
                                                  final verifyData = jsonDecode(
                                                      verifyResponse.body);
                                                  if (verifyResponse
                                                              .statusCode ==
                                                          200 &&
                                                      verifyData[
                                                              'resetToken'] !=
                                                          null) {
                                                    // Now reset the password
                                                    final resetResponse =
                                                        await http.post(
                                                      Uri.parse(
                                                          '${Config.baseUrl}/api/v1/auth/reset-password'),
                                                      headers: {
                                                        'Content-Type':
                                                            'application/json'
                                                      },
                                                      body: jsonEncode({
                                                        'resetToken':
                                                            verifyData[
                                                                'resetToken'],
                                                        'newPassword':
                                                            newPassword,
                                                      }),
                                                    );
                                                    final resetData =
                                                        jsonDecode(
                                                            resetResponse.body);
                                                    if (resetResponse
                                                                .statusCode ==
                                                            200 &&
                                                        resetData['status'] ==
                                                            'Success') {
                                                      AppFlushBar.showSuccess(
                                                          context,
                                                          message: resetData[
                                                                  'message'] ??
                                                              'Password reset successful!');
                                                      Navigator.pop(
                                                          context, true);
                                                    } else {
                                                      AppFlushBar.showError(
                                                          context,
                                                          message: resetData[
                                                                  'message'] ??
                                                              'Failed to reset password.');
                                                    }
                                                  } else {
                                                    AppFlushBar.showError(
                                                        context,
                                                        message: verifyData[
                                                                'message'] ??
                                                            'Invalid OTP.');
                                                  }
                                                } catch (e) {
                                                  AppFlushBar.showNetworkError(
                                                      context);
                                                }
                                              },
                                              child:
                                                  const Text('Reset Password'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    AppFlushBar.showError(
                                      context,
                                      message: data['message'] ??
                                          'Failed to send password reset email.',
                                    );
                                  }
                                } catch (e) {
                                  AppFlushBar.showNetworkError(context);
                                }
                              }
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontFamily: 'Inter-Regular',
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 45,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1D4C5E)),
                                  ),
                                )
                              : Material(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.transparent,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF245261),
                                            Color(0xFF4AA8C7)
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.25),
                                            offset: const Offset(0, 4),
                                            blurRadius: 1,
                                            spreadRadius: .3,
                                          )
                                        ]),
                                    child: InkWell(
                                      onTap: _handleLogin,
                                      borderRadius: BorderRadius.circular(30),
                                      child: const Center(
                                        child: Text(
                                          "Login",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => RegisterScreen()),
                                  );
                                },
                          child: const Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF245261),
                              fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email cannot be empty";
    }
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password cannot be empty";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }
    return null;
  }
}
