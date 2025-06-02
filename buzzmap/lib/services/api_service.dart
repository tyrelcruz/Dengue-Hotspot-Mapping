import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buzzmap/auth/config.dart';

class ApiService {
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('${Config.baseUrl}/api/v1/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      return {
        'status': response.statusCode,
        'data': data,
      };
    } catch (e) {
      return {
        'status': 0,
        'data': {'message': 'Network error: $e'},
      };
    }
  }
}
