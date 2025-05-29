import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buzzmap/auth/config.dart';

class AuthService {
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
        Uri.parse('${Config.baseUrl}/api/v1/auth/register'),
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

  static Future<bool> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/auth/check-email'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return response.statusCode == 200 && response.body == 'true';
    } catch (e) {
      return false;
    }
  }
}
