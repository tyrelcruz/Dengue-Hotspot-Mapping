import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/errors/flushbar.dart';
import 'package:buzzmap/pages/login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _showNewPassword = true;
  bool _showConfirmPassword = true;
  bool _isLoading = false;
  Timer? _passwordDebounceTimer;
  Timer? _confirmPasswordDebounceTimer;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordDebounceTimer?.cancel();
    _confirmPasswordDebounceTimer?.cancel();
    super.dispose();
  }

  void _validateNewPassword(String value) {
    _passwordDebounceTimer?.cancel();
    _passwordDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.length >= 8 &&
          RegExp(r'[A-Z]').hasMatch(value) &&
          RegExp(r'[a-z]').hasMatch(value) &&
          RegExp(r'[0-9]').hasMatch(value)) {
        AppFlushBar.showSuccess(
          context,
          message: 'Password meets all requirements!',
        );
      }
    });
  }

  void _validateConfirmPassword(String value) {
    _confirmPasswordDebounceTimer?.cancel();
    _confirmPasswordDebounceTimer =
        Timer(const Duration(milliseconds: 500), () {
      if (value == _newPasswordController.text && value.isNotEmpty) {
        AppFlushBar.showSuccess(
          context,
          message: 'Passwords match!',
        );
      }
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resetToken': widget.resetToken,
          'newPassword': _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'Success') {
        AppFlushBar.showSuccess(
          context,
          message: data['message'] ?? 'Password reset successful!',
        );

        // Navigate back to login screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        AppFlushBar.showError(
          context,
          message: data['message'] ?? 'Failed to reset password.',
        );
      }
    } catch (e) {
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
                    "NEW PASSWORD",
                    style: TextStyle(
                      fontFamily: 'Koulen',
                      fontSize: 50,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Please enter your new password below.",
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
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _validateNewPassword,
                    cursorColor: Colors.white,
                    cursorWidth: 2,
                    cursorRadius: const Radius.circular(2),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter your new password',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least one uppercase letter';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'Password must contain at least one lowercase letter';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Password must contain at least one number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _validateConfirmPassword,
                    cursorColor: Colors.white,
                    cursorWidth: 2,
                    cursorRadius: const Radius.circular(2),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Confirm your new password',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
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
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF315867))
                          : const Text(
                              "Reset Password",
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
