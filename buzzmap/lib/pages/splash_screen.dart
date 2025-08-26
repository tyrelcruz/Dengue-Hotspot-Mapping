import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showFirstImage = true;

  @override
  void initState() {
    super.initState();
    _startSplashFlow();
  }

  void _startSplashFlow() {
    // Use a single timer for better performance
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (timer.tick == 1) {
        // First tick - change image
        setState(() {
          _showFirstImage = !_showFirstImage;
        });
      } else if (timer.tick == 3) {
        // Third tick - navigate
        timer.cancel();
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      debugPrint('🧪 SplashScreen token check: $token');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      // Fallback to welcome screen if there's an error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        color: _showFirstImage
            ? Colors.white
            : const Color.fromRGBO(36, 82, 97, 1),
        child: Center(
          child: AnimatedCrossFade(
            duration: const Duration(seconds: 2),
            firstChild: SvgPicture.asset(
              'assets/icons/logo_darkbg.svg',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            secondChild: SvgPicture.asset(
              'assets/icons/logo_ligthbg.svg',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            crossFadeState: _showFirstImage
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
        ),
      ),
    );
  }
}
