import 'package:buzzmap/pages/welcome_screen.dart';
import 'package:buzzmap/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Adjustable button properties
  static const double buttonWidth = 200; // Adjust width
  static const double buttonHeight = 45; // Adjust height
  static const double buttonRadius = 30; // Adjust corner radius

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D4C5E),
      body: Column(
        children: [
          const SizedBox(height: 50),
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
                      fontSize: 50,
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
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Email",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFDBEBF3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Password",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      suffixIcon: const Icon(Icons.visibility_off),
                      filled: true,
                      fillColor: Color(0xFFDBEBF3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Checkbox(
                              value: false,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text("Remember Me"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Centered Login Button
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4C5E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    HomeScreen()), // Replace NextScreen with the name of your next screen
                          );
                        },
                        child: const Text("Login",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("or Login with"),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Centered Google Login Button
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://loodibee.com/wp-content/uploads/Google-Logo.png',
                              height: buttonHeight *
                                  1.5, // Icon size based on button height
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text("Don’t have an account? Sign up"),
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
