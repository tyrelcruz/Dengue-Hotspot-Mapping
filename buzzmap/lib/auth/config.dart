import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

//Login
class Config {
  static final String baseUrl =
      Platform.isAndroid ? 'http://10.0.2.2:4000' : 'http://localhost:4000';
}

//Register
class AuthService {
  static final String baseUrl =
      Platform.isAndroid ? 'http://10.0.2.2:4000' : 'http://localhost:4000';

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

  static Future<bool> registerUser(
      {required String fullName,
      required String email,
      required String password}) async {
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
