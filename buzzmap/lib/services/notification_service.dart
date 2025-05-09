import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:buzzmap/errors/flushbar.dart';
import 'package:buzzmap/config/config.dart';

class NotificationService with ChangeNotifier {
  final storage = FlutterSecureStorage();

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
      title: 'Report Submitted',
      message: message,
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
    );
  }

  Future<Map<String, dynamic>?> fetchReportDetails(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('No auth token found');
      }

      print('🔍 Fetching report details for ID: $reportId');
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$reportId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final report = jsonDecode(response.body);
        print('📄 Fetched report details:');
        print(json.encode(report));
        return report;
      } else {
        print('❌ Failed to fetch report details. Status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching report details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception('No auth token found');
      }

      // First, clean up notifications for deleted reports
      await cleanupDeletedReports(token);

      // Then fetch the updated notifications
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawNotifications = jsonDecode(response.body);
        print('📱 Fetched notifications: ${rawNotifications.length}');
        
        // Process notifications to include location data and ensure proper typing
        final List<Map<String, dynamic>> processedNotifications = await Future.wait(
          rawNotifications.map((notification) async {
            final Map<String, dynamic> typedNotification = Map<String, dynamic>.from(notification);
            print('🔍 Processing notification: ${typedNotification['_id']}');
            
            if (typedNotification['report'] != null) {
              final report = Map<String, dynamic>.from(typedNotification['report']);
              print('📄 Report data:');
              print(json.encode(report));
              print('📊 Report status: ${report['status']}');
              
              typedNotification['report'] = report;
              
              // If the report is validated, fetch its full details to get location data
              if (report['status']?.toLowerCase() == 'validated') {
                print('✅ Found validated report, fetching details...');
                final reportDetails = await fetchReportDetails(report['_id']);
                if (reportDetails != null) {
                  print('✅ Successfully fetched report details');
                  // Update the report with full details
                  typedNotification['report'] = reportDetails;
                  
                  // Extract location data
                  if (reportDetails['specific_location'] != null) {
                    final location = reportDetails['specific_location'];
                    print('📍 Found specific_location: $location');
                    if (location['coordinates'] != null) {
                      final coordinates = location['coordinates'];
                      print('📍 Found coordinates: $coordinates');
                      if (coordinates is List && coordinates.length >= 2) {
                        typedNotification['latitude'] = coordinates[1].toDouble();
                        typedNotification['longitude'] = coordinates[0].toDouble();
                        print('✅ Extracted coordinates - Lat: ${typedNotification['latitude']}, Long: ${typedNotification['longitude']}');
                      }
                    }
                  } else {
                    print('❌ No specific_location found in report details');
                  }
                } else {
                  print('❌ Failed to fetch report details');
                }
              }
              
              typedNotification['streetName'] = report['street_name'] ?? 'Unknown Street';
              print('📍 Street name: ${typedNotification['streetName']}');
            }
            
            return typedNotification;
          })
        );
        
        return processedNotifications;
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> cleanupDeletedReports(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/notifications/cleanup-deleted'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('🧹 Cleaned up ${result['deletedCount']} notifications with deleted reports');
      }
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }

  Future<void> deleteUserNotifications(String token, String username) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/notifications/user/$username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('🧹 Deleted ${result['deletedCount']} notifications for user $username');
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
  String? token =
      prefs.getString('authToken'); // Retrieve from SharedPreferences
  print('Retrieved Token: $token'); // Debugging line
  return token;
}
