import 'package:buzzmap/pages/otp_screen.dart';
import 'package:buzzmap/pages/splash_screen.dart';
import 'package:buzzmap/pages/welcome_screen.dart';

import 'package:buzzmap/pages/register_screen.dart';
import 'package:buzzmap/pages/home_screen.dart';
import 'package:buzzmap/pages/mapping_screen.dart';
import 'package:buzzmap/pages/community_screen.dart';
import 'package:buzzmap/pages/prevention_screen.dart';
import 'package:buzzmap/pages/about_screen.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:buzzmap/pages/login_screen.dart';
//Firebase Imports
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color surfaceLight;
  final Color surfaceDark;

  const CustomColors({
    required this.surfaceLight,
    required this.surfaceDark,
  });

  @override
  CustomColors copyWith({Color? surfaceLight, Color? surfaceDark}) {
    return CustomColors(
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceDark: surfaceDark ?? this.surfaceDark,
    );
  }

  @override
  CustomColors lerp(CustomColors? other, double t) {
    if (other == null) return this;
    return CustomColors(
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceDark: Color.lerp(surfaceDark, other.surfaceDark, t)!,
    );
  }
}

// Define colors as variables
const Color primaryColor = Color.fromRGBO(36, 82, 97, 1);
const Color secondaryColor = Color.fromRGBO(250, 221, 55, 1);
const Color surfaceColor = Color.fromRGBO(219, 235, 243, 1);
const Color surfaceDarkColor = Color.fromRGBO(96, 147, 175, 1);
const Color onPrimaryColor = Colors.white;
const Color onSecondaryColor = Colors.black;
const Color onSurfaceColor = Colors.black;
const Color errorColor = Colors.red;
const Color onErrorColor = Colors.white;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        // ✅ Initialize ScreenUtil here
        designSize: const Size(375, 812), // Adjust to your design reference
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'BuzzMap App',
            theme: ThemeData(
              colorScheme: const ColorScheme(
                primary: primaryColor,
                secondary: secondaryColor,
                surface: surfaceColor,
                onPrimary: onPrimaryColor,
                onSecondary: onSecondaryColor,
                onSurface: onSurfaceColor,
                error: errorColor,
                onError: onErrorColor,
                brightness: Brightness.light,
              ),
              textTheme: TextTheme(
                displayLarge: TextStyle(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Koulen',
                    color: primaryColor),
                displayMedium: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Koulen',
                    color: primaryColor),
                displaySmall: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Koulen',
                    color: primaryColor),
                headlineLarge: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Koulen',
                    color: primaryColor),
                headlineMedium: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Koulen',
                    color: primaryColor),
                headlineSmall: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Koulen',
                    color: primaryColor),
                titleLarge: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: primaryColor),
                titleMedium: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: primaryColor),
                titleSmall: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: primaryColor),
                bodyLarge: TextStyle(
                    fontSize: 16.sp, fontFamily: 'Inter', color: primaryColor),
                bodyMedium: TextStyle(
                    fontSize: 14.sp, fontFamily: 'Inter', color: primaryColor),
                bodySmall: TextStyle(
                    fontSize: 12.sp, fontFamily: 'Inter', color: primaryColor),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                contentPadding: EdgeInsets.symmetric(vertical: 3),
              ),
              scaffoldBackgroundColor: Colors.white,
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                titleTextStyle: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                backgroundColor: primaryColor,
              ),
              extensions: const <ThemeExtension<dynamic>>[
                CustomColors(
                  surfaceLight: surfaceColor,
                  surfaceDark: surfaceDarkColor,
                ),
              ],
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/otp': (context) => const OTPScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/mapping': (context) => const MappingScreen(),
              '/community': (context) => const CommunityScreen(),
              '/prevention': (context) => const PreventionScreen(),
              '/about': (context) => const AboutScreen(),
            },
          );
        });
  }
}
