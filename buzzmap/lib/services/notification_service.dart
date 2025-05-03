import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService with ChangeNotifier {
  final storage = FlutterSecureStorage(); // Instance of SecureStorage

  // Fetch notifications and return the result
  Future<List<dynamic>> fetchNotifications(BuildContext context) async {
    try {
      // Retrieve the token dynamically
      String? token = await getToken();

      if (token == null) {
        // Handle missing token error (e.g., navigate to login screen)
        print("Error: No token found");
        return [];
      }

      final response = await http.get(
        Uri.parse('http://localhost:4000/api/v1/notifications/'),
        headers: {
          'Authorization': 'Bearer $token', // Pass the token dynamically
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> notifications = json.decode(response.body);
        return notifications; // Return the notifications
      } else {
        print(
            "Failed to load notifications. Status Code: ${response.statusCode}");
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      throw Exception('Failed to load notifications');
    }
  }

  // Retrieve the token from secure storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('authToken'); // Retrieve from SharedPreferences
    print('Retrieved Token: $token'); // Debugging line
    return token;
  }
}
