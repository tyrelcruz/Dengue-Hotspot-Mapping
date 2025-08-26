import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/errors/flushbar.dart';
import 'package:buzzmap/pages/new_password_screen.dart';

class ResetPasswordOTPScreen extends StatefulWidget {
  final String email;

  const ResetPasswordOTPScreen({super.key, required this.email});

  @override
  State<ResetPasswordOTPScreen> createState() => _ResetPasswordOTPScreenState();
}

class _ResetPasswordOTPScreenState extends State<ResetPasswordOTPScreen> {
  String enteredOtp = '';
  bool isLoading = false;
  Timer? _otpDebounceTimer;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpDebounceTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _validateOtp(String value) {
    _otpDebounceTimer?.cancel();
    _otpDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.length == 4) {
        setState(() {
          enteredOtp = value;
        });
        AppFlushBar.showSuccess(
          context,
          message: 'OTP entered successfully! Click verify to proceed.',
        );
      }
    });
  }

  Future<void> verifyOtp() async {
    if (enteredOtp.isEmpty) {
      AppFlushBar.showError(
        context,
        message: 'Please enter the OTP',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = '${Config.baseUrl}/api/v1/auth/verify-otp';
      final body = {
        'email': widget.email,
        'otp': enteredOtp,
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
          message: data['message'] ?? 'OTP verified successfully!',
        );

        // Navigate to new password screen with the reset token
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                email: widget.email,
                resetToken: data['resetToken'],
              ),
            ),
          );
        }
      } else {
        AppFlushBar.showError(
          context,
          message: data['message'] ?? 'Failed to verify OTP.',
        );
      }
    } catch (e, stackTrace) {
      print("DEBUG: Error occurred: $e");
      print("DEBUG: Stack trace: $stackTrace");
      AppFlushBar.showNetworkError(context);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resendOtp() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = '${Config.baseUrl}/api/v1/auth/request-otp';
      final body = {'email': widget.email, 'purpose': 'password-reset'};

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
          message: data['message'] ?? 'OTP resent successfully!',
        );
      } else {
        AppFlushBar.showError(
          context,
          message: data['message'] ?? 'Failed to resend OTP.',
        );
      }
    } catch (e, stackTrace) {
      print("DEBUG: Error occurred: $e");
      print("DEBUG: Stack trace: $stackTrace");
      AppFlushBar.showNetworkError(context);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF315867),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "VERIFY OTP",
                style: TextStyle(
                  fontFamily: 'Koulen',
                  fontSize: 50,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "We've sent a one-time password (OTP) to ${widget.email}.\n"
                "Enter the code to reset your password.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _otpController,
                onChanged: (value) {
                  if (value.length == 4) {
                    _validateOtp(value);
                  }
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  activeFillColor: Colors.white.withOpacity(0.2),
                  inactiveFillColor: Colors.white.withOpacity(0.1),
                  selectedFillColor: Colors.white.withOpacity(0.2),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white,
                  selectedColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                enableActiveFill: true,
                textStyle: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: isLoading ? null : resendOtp,
                child: const Text.rich(
                  TextSpan(
                    text: "Didn't receive an OTP? ",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: "Resend",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: isLoading ? null : verifyOtp,
                child: isLoading
                    ? CircularProgressIndicator(color: Color(0xFF315867))
                    : const Text(
                        "Verify",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF315867),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
