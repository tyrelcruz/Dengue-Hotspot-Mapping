import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OTPScreen(),
  ));
}

class OTPScreen extends StatelessWidget {
  const OTPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Adjust these values to change character sizes
    const double character1Size = 420; // Left character size
    const double character2Size = 420; // Right character size

    return Scaffold(
      backgroundColor: const Color(0xFF315867),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content (non-scrollable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Title
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
                  // Subtitle
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
                  // OTP Input
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
                    onCompleted: (pin) => print("Entered OTP: $pin"),
                  ),
                  SizedBox(height: 20),
                  // Resend OTP
                  TextButton(
                    onPressed: () {},
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
                  // Verify Button
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
                    onPressed: () {},
                    child: const Text(
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

            // Bottom-left character (fixed position)
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

            // Bottom-right character (fixed position)
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
}
