import 'package:buzzmap/pages/login_screen.dart';
import 'package:buzzmap/pages/otp_screen.dart';
import 'package:buzzmap/pages/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buzzmap/errors/flushbar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/auth/auth_service.dart';

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
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _showPasswordPopup = false;
  bool _isRegistering = false; // Add loading state

  // Customizable text field properties
  final double textFieldHeight = 38.0;
  final double textFieldBorderRadius = 30.0;
  final Color textFieldFillColor = const Color(0xFF99C0D3);
  final EdgeInsets textFieldContentPadding =
      const EdgeInsets.symmetric(horizontal: 20);

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Password requirements check
  bool get _hasMinLength =>
      _passwordController.text.length >= 8 &&
      _passwordController.text.length <= 20;
  bool get _hasCapital => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _noSpaces => !_passwordController.text.contains(' ');

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
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Config.googleClientId,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return;

      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      final bool success = await AuthService.googleLogin(idToken: idToken);
      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign in failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45),
          child: Center(
            child: Container(
              width: 240,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Arrow pointing up
                  Positioned(
                    top: -8,
                    left: 20,
                    child: CustomPaint(
                      size: const Size(16, 8),
                      painter: ArrowPainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4C5E),
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildReqRow(_hasMinLength, '8-20 ', 'Characters'),
                        _buildReqRow(
                            _hasCapital, 'At least ', 'one capital letter',
                            highlightRed: !_hasCapital),
                        _buildReqRow(_hasNumber, 'At least ', 'one number'),
                        _buildReqRow(_noSpaces, '', 'No spaces'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildReqRow(bool met, String prefix, String main,
      {bool highlightRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            color: met ? const Color(0xFF1D4C5E) : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            prefix,
            style: TextStyle(
              color: met
                  ? const Color(0xFF1D4C5E)
                  : (highlightRed ? Colors.red : Colors.black87),
              fontWeight: FontWeight.w500,
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
          ),
          Flexible(
            child: Text(
              main,
              style: TextStyle(
                color: met
                    ? const Color(0xFF1D4C5E)
                    : (highlightRed ? Colors.red : Colors.black87),
                fontWeight:
                    highlightRed && !met ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.only(
                    top: 1, left: 20, right: 20, bottom: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF1D4C5E)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WelcomeScreen()),
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
                padding: const EdgeInsets.only(
                    top: 0, bottom: 0, left: 40, right: 40),
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
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: TextField(
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            controller: _passwordController,
                            onChanged: (val) {
                              if (_overlayEntry != null) {
                                _showOverlay();
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: textFieldFillColor,
                              contentPadding: textFieldContentPadding,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    textFieldBorderRadius),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    textFieldBorderRadius),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    textFieldBorderRadius),
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
                      ),
                      const SizedBox(height: 15),
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
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors
                                      .blue; // Background color when checked
                                }
                                return const Color.fromARGB(0, 255, 255,
                                    255); // Background color when unchecked
                              }),
                              checkColor:
                                  Colors.white, // Color of the checkmark
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
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
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
                              backgroundColor: const Color(0xFFF7B84B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isRegistering
                                ? null
                                : () async {
                                    setState(() {
                                      _isRegistering = true;
                                    });
                                    final firstName =
                                        _firstNameController.text.trim();
                                    final lastName =
                                        _lastNameController.text.trim();
                                    final email = _emailController.text.trim();
                                    final password = _passwordController.text;
                                    final confirmPassword =
                                        _confirmPasswordController.text;

                                    // Validation checks
                                    if (firstName.isEmpty ||
                                        lastName.isEmpty ||
                                        email.isEmpty ||
                                        password.isEmpty ||
                                        confirmPassword.isEmpty) {
                                      AppFlushBar.showError(
                                        context,
                                        message: 'All fields are required!',
                                      );
                                      setState(() {
                                        _isRegistering = false;
                                      });
                                      return;
                                    }

                                    if (!_agreeToTerms) {
                                      AppFlushBar.showCustom(
                                        context,
                                        title: 'Terms Required',
                                        message:
                                            'Please agree to the Terms and Conditions.',
                                        backgroundColor: Colors.orange,
                                      );
                                      setState(() {
                                        _isRegistering = false;
                                      });
                                      return;
                                    }

                                    if (!_isValidEmail(email)) {
                                      AppFlushBar.showCustom(
                                        context,
                                        title: 'Invalid Email',
                                        message:
                                            'Please enter a valid email address.',
                                        backgroundColor: Colors.orange,
                                      );
                                      setState(() {
                                        _isRegistering = false;
                                      });
                                      return;
                                    }

                                    if (!_isValidPassword(password)) {
                                      AppFlushBar.showCustom(
                                        context,
                                        title: 'Weak Password',
                                        message:
                                            'Password must have at least 8 characters, uppercase, lowercase, number, and a special character.',
                                        backgroundColor: Colors.orange,
                                      );
                                      setState(() {
                                        _isRegistering = false;
                                      });
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      AppFlushBar.showError(
                                        context,
                                        title: 'Mismatch',
                                        message: 'Passwords do not match.',
                                      );
                                      setState(() {
                                        _isRegistering = false;
                                      });
                                      return;
                                    }

                                    final baseUrl = Config.baseUrl;
                                    final checkEmailUrl = Uri.parse(
                                        '$baseUrl/api/v1/auth/check-email');

                                    try {
                                      final response = await http.post(
                                        checkEmailUrl,
                                        headers: {
                                          "Content-Type": "application/json"
                                        },
                                        body: jsonEncode({"email": email}),
                                      );

                                      if (response.statusCode == 200 &&
                                          response.body == 'true') {
                                        AppFlushBar.showError(
                                          context,
                                          title: 'Account Exists',
                                          message:
                                              'An account with this email already exists.',
                                        );
                                        setState(() {
                                          _isRegistering = false;
                                        });
                                        return;
                                      }

                                      final registerUrl = Uri.parse(
                                          '$baseUrl/api/v1/auth/register');
                                      final registerResponse = await http.post(
                                        registerUrl,
                                        headers: {
                                          "Content-Type": "application/json"
                                        },
                                        body: jsonEncode({
                                          "username": "$firstName $lastName",
                                          "email": email,
                                          "password": password,
                                          "role": "user",
                                        }),
                                      );

                                      if (registerResponse.statusCode == 200 ||
                                          registerResponse.statusCode == 201) {
                                        AppFlushBar.showSuccess(
                                          context,
                                          message:
                                              'Account created successfully!',
                                        );

                                        Future.delayed(Duration(seconds: 1),
                                            () {
                                          setState(() {
                                            _isRegistering = false;
                                          });
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => OTPScreen(
                                                    email:
                                                        _emailController.text)),
                                          );
                                        });
                                      } else {
                                        final errorData =
                                            jsonDecode(registerResponse.body);
                                        final errorMessage = errorData['errors']
                                                ?[0] ??
                                            errorData['message'] ??
                                            'Registration failed. Please try again.';
                                        AppFlushBar.showError(
                                          context,
                                          message: errorMessage,
                                        );
                                        setState(() {
                                          _isRegistering = false;
                                        });
                                      }
                                    } catch (e) {
                                      AppFlushBar.showNetworkError(context);
                                      setState(() {
                                        _isRegistering = false;
                                      });
                                    }
                                  },
                            child: _isRegistering
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

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
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.white),
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
        ],
      ),
    );
  }
}

// Add this class at the end of the file
class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
