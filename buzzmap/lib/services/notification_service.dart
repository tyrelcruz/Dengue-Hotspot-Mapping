import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:buzzmap/errors/flushbar.dart';
import 'package:buzzmap/config/config.dart';
import 'package:buzzmap/services/http_client.dart';
import 'package:buzzmap/errors/flushbar.dart';

class NotificationService with ChangeNotifier {
  final storage = FlutterSecureStorage();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _httpClient = HttpClient();

  static Future<void> showLocationToast(
    BuildContext context,
    String message,
  ) async {
    await Flushbar(
      message: message,
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.BOTTOM,
      forwardAnimationCurve: Curves.easeInOut,
      reverseAnimationCurve: Curves.easeInOut,
    ).show(context);
  }

  // Show the notification with the empathetic message
  static Future<void> showEmpatheticFeedback(
      BuildContext context, String message) async {
    await AppFlushBar.showCustom(
      context,
      title: 'Thank You for Reporting!',
      message: message,
      backgroundColor: Colors.green,
    );
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>?> fetchReportDetails(String reportId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ No auth token found');
        return null;
      }

      print('🔑 Using auth token: $token');
      final url = '${Config.baseUrl}/api/v1/reports/$reportId';
      print('🌐 Fetching report details from: $url');

      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Headers: ${response.headers}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 Decoded response data:');
        print(json.encode(data));

        if (data['success'] == true && data['data'] != null) {
          final report = data['data'];
          print('📄 Full report data:');
          print(json.encode(report));

          // Check for location data in different possible fields
          if (report['specific_location'] != null) {
            print('✅ Found specific_location in report');
            final location = report['specific_location'];
            print('📍 Location data:');
            print(json.encode(location));

            if (location['coordinates'] != null) {
              print('🎯 Found coordinates in location');
              final coordinates = location['coordinates'];
              print('📌 Raw coordinates: $coordinates');

              if (coordinates is List && coordinates.length >= 2) {
                // Note: coordinates are in [longitude, latitude] format
                final longitude = coordinates[0].toDouble();
                final latitude = coordinates[1].toDouble();
                print(
                    '✅ Successfully extracted coordinates: $latitude, $longitude');
                return report;
              } else {
                print('❌ Invalid coordinates format: $coordinates');
              }
            } else {
              print('❌ No coordinates found in location data');
            }
          } else {
            print('❌ No specific_location found in report');
          }
        } else {
          print('❌ Invalid response format or missing data');
          print('Response data:');
          print(json.encode(data));
        }
      } else {
        print(
            '❌ Failed to fetch report details. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ Error fetching report details: $e');
      if (e is TimeoutException) {
        print('⏰ Request timed out');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(
      BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('No auth token found');
      }

      // First, clean up notifications for deleted reports
      await cleanupDeletedReports(token);

      // Then fetch the updated notifications
      final response = await _httpClient.get(
        '${Config.baseUrl}/api/v1/notifications',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawNotifications = jsonDecode(response.body);
        print('📱 Fetched notifications: ${rawNotifications.length}');

        // Debug log the raw notification data
        for (var notification in rawNotifications) {
          print('📄 Raw notification data:');
          print(json.encode(notification));

          if (notification['report'] != null) {
            print('📍 Report data:');
            print(json.encode(notification['report']));

            if (notification['report']['specific_location'] != null) {
              print('🗺️ Location data:');
              print(json.encode(notification['report']['specific_location']));
            }
          }
        }

        return rawNotifications.cast<Map<String, dynamic>>();
      } else {
        print(
            '❌ Failed to fetch notifications. Status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> cleanupDeletedReports(String token) async {
    try {
      final response = await _httpClient.delete(
        '${Config.baseUrl}/api/v1/notifications/cleanup-deleted',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print(
            '🧹 Cleaned up ${result['deletedCount']} notifications with deleted reports');
      }
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }

  Future<void> deleteUserNotifications(String token, String username) async {
    try {
      final response = await _httpClient.delete(
        '${Config.baseUrl}/api/v1/notifications/user/$username',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print(
            '🧹 Deleted ${result['deletedCount']} notifications for user $username');
      }
    } catch (e) {
      print('❌ Error deleting user notifications: $e');
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
  String? token = prefs.getString('authToken');
  print('Retrieved Token: $token');
  return token;
}
