import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/errors/flushbar.dart';
import 'package:buzzmap/pages/reset_password_otp_screen.dart';
import 'package:flutter/foundation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _validateEmail(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty &&
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        AppFlushBar.showSuccess(
          context,
          message: 'Valid email format!',
        );
      }
    });
  }

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${Config.baseUrl}/api/v1/auth/request-otp';
      final body = {
        'email': _emailController.text.trim(),
        'purpose': 'password-reset'
      };

      print("DEBUG: Platform: ${Platform.operatingSystem}");
      print("DEBUG: Base URL: ${Config.baseUrl}");
      print("DEBUG: Full URL: $url");
      print("DEBUG: Request body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("DEBUG: Response status code: ${response.statusCode}");
      print("DEBUG: Response headers: ${response.headers}");
      print("DEBUG: Response body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        AppFlushBar.showSuccess(
          context,
          message: data['message'] ?? 'Password reset email sent!',
        );

        // Navigate to OTP screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordOTPScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } else {
        AppFlushBar.showError(
          context,
          message: data['message'] ?? 'Failed to send password reset email.',
        );
      }
    } catch (e, stackTrace) {
      print("DEBUG: Error occurred: $e");
      print("DEBUG: Stack trace: $stackTrace");
      AppFlushBar.showNetworkError(context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF315867),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "FORGOT PASSWORD",
                    style: TextStyle(
                      fontFamily: 'Koulen',
                      fontSize: 50,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Enter your email address and we'll send you instructions to reset your password.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _validateEmail,
                    cursorColor: Colors.white,
                    cursorWidth: 2,
                    cursorRadius: const Radius.circular(2),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter your email address',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
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
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _isLoading ? null : _requestPasswordReset,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF315867))
                          : const Text(
                              "Send Reset Link",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF315867),
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
    );
  }
}
