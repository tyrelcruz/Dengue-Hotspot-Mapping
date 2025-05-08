import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart'; // Import the template file
import 'package:another_flushbar/flushbar.dart';  // Updated import
import 'package:buzzmap/errors/flushbar.dart';

class NotificationService with ChangeNotifier {
  final storage = FlutterSecureStorage(); // Instance of SecureStorage

  static Future<void> showLocationToast(
    BuildContext context,
    String message,
  ) async {
    await Flushbar(
      message: message,
      backgroundColor: Colors.red, // Red color for "outside"
      duration: Duration(seconds: 3), // Duration of the notification
      flushbarPosition:
          FlushbarPosition.BOTTOM, // Position at the bottom (like a Toast)
      forwardAnimationCurve: Curves.easeInOut, // Animation effect for fade-in
      reverseAnimationCurve: Curves.easeInOut, // Animation effect for fade-out
    ).show(context);
  }

  // Show the notification with the empathetic message
  static Future<void> showEmpatheticFeedback(
      BuildContext context, String message) async {
    await AppFlushBar.showCustom(
      context,
      title: 'Report Submitted',
      message: message,
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    );
  }

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

  // Example for showing success notification
  static Future<void> showSuccess(BuildContext context, String message) async {
    await AppFlushBar.showSuccess(
      context,
      message: message,
      duration: Duration(seconds: 3),
    );
  }

  // Example for showing error notification
  static Future<void> showError(BuildContext context, String message) async {
    await AppFlushBar.showError(
      context,
      message: message,
      duration: Duration(seconds: 3),
    );
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
