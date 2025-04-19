import 'package:buzzmap/pages/login_screen.dart';
import 'package:buzzmap/pages/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

//Firebase Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Database - Remove later
final TextEditingController _firstNameController = TextEditingController();
final TextEditingController _lastNameController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
final TextEditingController _confirmPasswordController =
    TextEditingController();

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String _firstNameError = ''; // Error message for first name
  String _errorMessage = ''; // Error message to display

  // Customizable text field properties
  final double textFieldHeight = 38.0;
  final double textFieldBorderRadius = 30.0;
  final Color textFieldFillColor = const Color(0xFF99C0D3);
  final EdgeInsets textFieldContentPadding =
      const EdgeInsets.symmetric(horizontal: 20);

  Widget _buildTermSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        Text(
          content,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // Check if user already exists on your server
        final baseUrl = Platform.isAndroid
            ? 'http://10.0.2.2:4000'
            : 'http://localhost:4000';

        final checkEmailUrl = Uri.parse('$baseUrl/api/v1/auth/check-email');

        final response = await http.post(
          checkEmailUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": user.email}),
        );

        if (response.statusCode == 200 && response.body == 'false') {
          // Register the user if not yet registered in your backend
          final registerUrl = Uri.parse('$baseUrl/api/v1/auth/register');

          await http.post(
            registerUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": user.displayName ?? 'Google User',
              "email": user.email,
              "password":
                  'google_oauth', // Placeholder or handle differently in backend
            }),
          );
        }

        // Navigate to login or home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed. Try again.';
      });
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Align(
            alignment: Alignment.center,
            child: Text(
              "Terms and Conditions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4C5E),
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Last Updated: April 11, 2025",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 8),
                    _buildTermSection(
                      "1. Acceptance of Terms",
                      "By accessing or using the BuzzMap application, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use the application.",
                    ),
                    _buildTermSection(
                      "2. User Responsibilities",
                      "You agree to use BuzzMap only for lawful purposes and in a way that does not infringe the rights of, restrict, or inhibit anyone else's use and enjoyment of the application.",
                    ),
                    _buildTermSection(
                      "3. Data Collection and Privacy",
                      "BuzzMap collects personal information to provide and improve our services. By using the application, you consent to the collection and use of information in accordance with our Privacy Policy.",
                    ),
                    _buildTermSection(
                      "4. Dengue Reporting Accuracy",
                      "Users are responsible for providing accurate information when reporting dengue cases. False or misleading reports may result in account suspension.",
                    ),
                    _buildTermSection(
                      "5. Intellectual Property",
                      "All content, features, and functionality of BuzzMap are the exclusive property of the developers and are protected by international copyright laws.",
                    ),
                    _buildTermSection(
                      "6. Limitation of Liability",
                      "BuzzMap and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the application.",
                    ),
                    _buildTermSection(
                      "7. Changes to Terms",
                      "We reserve the right to modify these terms at any time. Your continued use of BuzzMap after any changes constitutes your acceptance of the new terms.",
                    ),
                    _buildTermSection(
                      "8. Governing Law",
                      "These terms shall be governed by and construed in accordance with the laws of the jurisdiction where the application is developed.",
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Close",
                style: TextStyle(color: Color(0xFF1D4C5E)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Email validation function
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Password validation function
  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding:
                const EdgeInsets.only(top: 1, left: 20, right: 20, bottom: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1D4C5E)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()),
                    );
                  },
                ),
                SvgPicture.asset(
                  'assets/icons/logo_ligthbg.svg',
                  height: 30,
                ),
              ],
            ),
          ),
          const SizedBox(height: 0),
          const Text(
            "JOIN BUZZMAP!",
            style: TextStyle(
                fontFamily: 'Koulen',
                fontSize: 45,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1D4C5E)),
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 0, bottom: 0, left: 40, right: 40),
            child: Text(
              "Sign Up to join us today and be part of the movement to track, report, and prevent dengue outbreaks.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D4C5E)),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(35),
              decoration: const BoxDecoration(
                color: Color(0xFF1D4C5E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "First Name",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: textFieldHeight,
                              child: TextField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: textFieldFillColor,
                                  contentPadding: textFieldContentPadding,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        textFieldBorderRadius),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            if (_firstNameError.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  _firstNameError,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Last Name",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: textFieldHeight,
                              child: TextField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: textFieldFillColor,
                                  contentPadding: textFieldContentPadding,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        textFieldBorderRadius),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Email",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: textFieldHeight,
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: textFieldFillColor,
                        contentPadding: textFieldContentPadding,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(textFieldBorderRadius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Password",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: textFieldHeight,
                    child: TextField(
                      obscureText: _obscurePassword,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: textFieldFillColor,
                        contentPadding: textFieldContentPadding,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(textFieldBorderRadius),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Password must be At least 8 characters long, contains both uppercase and lowercase letters, includes at least one number, and contains one special character (e.g., !, @, #, \$)",
                    style: TextStyle(
                      fontFamily: 'Inter-Italic-VariableFont',
                      fontStyle: FontStyle.italic,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Confirm Password",
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: textFieldHeight,
                    child: TextField(
                      obscureText: _obscureConfirmPassword,
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: textFieldFillColor,
                        contentPadding: textFieldContentPadding,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(textFieldBorderRadius),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ClipOval(
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors
                                  .blue; // Background color when checked
                            }
                            return const Color.fromARGB(0, 255, 255,
                                255); // Background color when unchecked
                          }),
                          checkColor: Colors.white, // Color of the checkmark
                          side: const BorderSide(
                              color: Color.fromARGB(255, 255, 255, 255),
                              width: 2), // Border color and width
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: _showTermsAndConditions,
                        child: Text(
                          "I agree to the Terms and Conditions",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 11, // 👈 Set the desired font size here
                          color: Colors.red,
                          fontWeight: FontWeight
                              .w500, // Optional: You can change this based on your need
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF7B84B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          setState(() {
                            _errorMessage = '';
                          });

                          final firstName = _firstNameController.text.trim();
                          final lastName = _lastNameController.text.trim();
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          final confirmPassword =
                              _confirmPasswordController.text;

                          // Basic validation
                          if (firstName.isEmpty ||
                              lastName.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty) {
                            setState(() {
                              _errorMessage = 'All fields are required!';
                            });
                            return;
                          }

                          if (!_isValidEmail(email)) {
                            setState(() {
                              _errorMessage =
                                  'Please enter a valid email address.';
                            });
                            return;
                          }

                          if (!_isValidPassword(password)) {
                            setState(() {
                              _errorMessage =
                                  'Password must have at least 8 characters, uppercase, lowercase, number, and a special character.';
                            });
                            return;
                          }

                          if (password != confirmPassword) {
                            setState(() {
                              _errorMessage = 'Passwords do not match.';
                            });
                            return;
                          }

                          // Proceed to check if email already exists
                          final baseUrl = Platform.isAndroid
                              ? 'http://10.0.2.2:4000'
                              : 'http://localhost:4000';
                          final checkEmailUrl =
                              Uri.parse('$baseUrl/api/v1/auth/check-email');

                          try {
                            final response = await http.post(
                              checkEmailUrl,
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"email": email}),
                            );

                            if (response.statusCode == 200 &&
                                response.body == 'true') {
                              setState(() {
                                _errorMessage =
                                    'An account with this email already exists.';
                              });
                              return;
                            }

                            // Register new user
                            final registerUrl =
                                Uri.parse('$baseUrl/api/v1/auth/register');
                            final registerResponse = await http.post(
                              registerUrl,
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({
                                "username": "$firstName $lastName",
                                "email": email,
                                "password": password,
                              }),
                            );

                            if (registerResponse.statusCode == 200 ||
                                registerResponse.statusCode == 201) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                              );
                            } else {
                              setState(() {
                                _errorMessage =
                                    'Registration failed. Please try again.';
                              });
                            }
                          } catch (e) {
                            setState(() {
                              _errorMessage =
                                  'Something went wrong. Please check your connection.';
                            });
                          }

                          const TextStyle errorTextStyle = TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white70)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "or Sign Up with",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Google Sign Up Button
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _handleGoogleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/google_logo.png',
                                height: 74),
                            const SizedBox(width: 10),
                            const Text(
                              "",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4C5E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),

                  // "Already have an account?" Text
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 14.0, color: Colors.white),
                          children: [
                            TextSpan(text: "Already have an account? "),
                            TextSpan(
                              text: "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
