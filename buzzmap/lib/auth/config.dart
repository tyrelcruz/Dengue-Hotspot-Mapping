import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

//Login
class Config {
  static String get baseUrl {
    if (Platform.isIOS) {
      return 'http://localhost:4000'; // For iOS simulator
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000'; // For Android emulator
    }
    return 'http://192.168.1.45:4000'; // For physical devices
  }

  // Add these URLs
  static String get verifyOtpUrl => '$baseUrl/api/v1/auth/verify-otp';
  static String get resendOtpUrl => '$baseUrl/api/v1/auth/resend-otp';
  static String get googleLoginUrl => '$baseUrl/api/v1/auth/google-login';
  static String get createPostUrl => '$baseUrl/api/v1/reports';
  static String get createPostwImageUrl => '$baseUrl/api/v1/posts';
  static String get userProfileUrl => '$baseUrl/api/v1/auth/me';
}

//AuthService
class AuthService {
  static String get baseUrl => Config.baseUrl;

  static Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/check-email'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return response.statusCode == 200 && response.body == 'true';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> googleLogin({required String idToken}) async {
    try {
      final response = await http.post(
        Uri.parse(Config.googleLoginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': idToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": fullName,
          "email": email,
          "password": password,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
