import 'package:buzzmap/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:buzzmap/auth/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:buzzmap/errors/flushbar.dart';

class OTPScreen extends StatefulWidget {
  final String email;

  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  String enteredOtp = '';
  bool isLoading = false;

  void showCustomizeFlushbar(String message) {
    print("DEBUG: Showing flushbar with message: $message");
    Flushbar(
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: Colors.black87,
      flushbarPosition: FlushbarPosition.BOTTOM,
    )..show(context);
  }

  Future<void> verifyOtp() async {
    if (enteredOtp.length != 4) {
      showCustomizeFlushbar("Please enter a valid 4-digit OTP");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(Config.verifyOtpUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'otp': enteredOtp,
          'purpose': 'account-verification',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        FocusScope.of(context).unfocus();
        showCustomizeFlushbar(data['message'] ?? 'Verification successful');

        // Use rootNavigator to ensure navigation works
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        showCustomizeFlushbar(data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      showCustomizeFlushbar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resendOtp() async {
    print("DEBUG: resendOtp method started");
    setState(() {
      isLoading = true;
    });

    try {
      print("DEBUG: Making HTTP request to resend OTP");
      final url = Uri.parse(Config.resendOtpUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'purpose': 'account-verification',
        }),
      );
      print(
          "DEBUG: Resend OTP response received - Status code: ${response.statusCode}");

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        print("DEBUG: OTP resent successfully");
        showCustomizeFlushbar(data['message'] ?? 'OTP sent successfully!');
      } else {
        print("DEBUG: Failed to resend OTP");
        showCustomizeFlushbar(data['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      print("DEBUG: Exception in resendOtp: ${e.toString()}");
      showCustomizeFlushbar('Error: ${e.toString()}');
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
    const double character1Size = 420;
    const double character2Size = 420;

    return Scaffold(
      backgroundColor: const Color(0xFF315867),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "ALMOST THERE...",
                    style: TextStyle(
                      fontFamily: 'Koulen',
                      fontSize: 50,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "We've sent a one-time password (OTP) to your email.\n"
                    "Enter the code to verify your account and continue.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 30),
                  Pinput(
                    length: 4,
                    defaultPinTheme: PinTheme(
                      width: 70,
                      height: 90,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onCompleted: (pin) {
                      setState(() {
                        enteredOtp = pin;
                      });
                      print("DEBUG: OTP entered: $pin");
                    },
                  ),
                  SizedBox(height: 20),
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 12),
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
            Positioned(
              left: -120,
              bottom: -30,
              child: IgnorePointer(
                child: SizedBox(
                  width: character1Size,
                  height: character1Size,
                  child: Image.asset(
                    'assets/images/otp_character.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -100,
              bottom: -30,
              child: IgnorePointer(
                child: SizedBox(
                  width: character2Size,
                  height: character2Size,
                  child: Image.asset(
                    'assets/images/otp_character1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print("DEBUG: OTPScreen widget disposed");
    super.dispose();
  }
}
