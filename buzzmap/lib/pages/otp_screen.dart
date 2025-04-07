import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      backgroundColor: Color(0xFF315867), // Background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
              SizedBox(height: 30),

              // Title
              Text(
                "ALMOST THERE...",
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 15),

              // Subtitle
              Text(
                "We've sent a one-time password (OTP) to your email.\n"
                "Enter the code to verify your account and continue.",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30),

              // OTP Input
              Pinput(
                length: 4,
                defaultPinTheme: PinTheme(
                  width: 60,
                  height: 60,
                  textStyle: GoogleFonts.montserrat(
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
                child: Text.rich(
                  TextSpan(
                    text: "Didn’t receive an OTP? ",
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: "Resend",
                        style: GoogleFonts.montserrat(
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
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: () {},
                child: Text(
                  "Verify",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF315867),
                  ),
                ),
              ),
              Spacer(),

              // Illustration
              Image.asset(
                'assets/images/otp_character.png', // Add this image in assets
                
                height: 100,
              ),
              Image.asset(
                'assets/images/otp_character1.png', // Add this image in assets
                height: 100,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
