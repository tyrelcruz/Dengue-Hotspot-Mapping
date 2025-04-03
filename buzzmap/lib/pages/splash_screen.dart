import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

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
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _showFirstImage = !_showFirstImage;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      });
    });
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
