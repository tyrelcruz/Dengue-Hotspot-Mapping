import 'package:buzzmap/pages/login_screen.dart';
import 'package:buzzmap/pages/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    // Scale values for responsiveness
    double logoHeight = screenHeight * 0.1;
    double imageHeight = screenHeight * 0.4;
    double paddingHorizontal = screenWidth * 0.05;
    double paddingVertical = screenHeight * 0.02;
    double buttonPaddingHorizontal = screenWidth * 0.14;
    double buttonPaddingVertical = screenHeight * 0.01;
    double titleFontSize = 70 * MediaQuery.of(context).textScaleFactor;
    double subtitleFontSize = 15 * MediaQuery.of(context).textScaleFactor;
    double textContent = 12 * MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: const Color(0xFF1D4C5E),
      body: Stack(
        children: [
          // Main Column Section
          Column(
            children: [
              SizedBox(height: screenHeight * 0.08),
              Align(
                alignment: Alignment.topCenter,
                child: SvgPicture.asset(
                  'assets/icons/logo_darkbg.svg',
                  height: logoHeight,
                ),
              ),
              SizedBox(height: screenHeight * 0.37),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: paddingVertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTitleText(titleFontSize),
                      _buildSubtitleText(subtitleFontSize),
                      SizedBox(height: screenHeight * 0.02),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1D4C5E),
                          ),
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'BuzzMap',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text:
                                  ' empowers you to protect your\n community by tracking, reporting, and\n preventing dengue outbreaks together.',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      const Text(
                        "Get started now – Log in or Sign up to join\n the fight against dengue!",
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1D4C5E),
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Login Button Section
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF245261), Color(0xFF4AA8C7)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonPaddingHorizontal,
                                  vertical: buttonPaddingVertical,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          LoginScreen()), // Replace NextScreen with the name of your next screen
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                              width: screenWidth * 0.04,
                              height: screenWidth * 0.06),
                          // Sign Up Button Section
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF8A900), Color(0xFFFADD37)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: buttonPaddingHorizontal,
                                  vertical: buttonPaddingVertical,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          RegisterScreen()), // Replace NextScreen with the name of your next screen
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xFF1D4C5E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Positioned Image Section
          Positioned(
            top: screenHeight * 0.2,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/welcome_character.png',
                  height: imageHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Title Text Widget
  Widget _buildTitleText(double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 0),
      child: Text(
        "WELCOME!",
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Koulen',
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1D4C5E),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Subtitle Text Widget
  Widget _buildSubtitleText(double fontSize) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Text(
        "Your dengue defense starts here.",
        style: TextStyle(
          fontFamily: 'Inter-Regular',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1D4C5E),
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
