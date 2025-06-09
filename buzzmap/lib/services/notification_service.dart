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
  List<Map<String, dynamic>> _cachedNotifications = [];
  DateTime? _lastFetchTime;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // Cache duration - only refresh notifications every 30 seconds
  static const Duration _cacheDuration = Duration(seconds: 30);

  // Initialize the service
  void initialize() {
    _startPeriodicRefresh();
  }

  // Start periodic refresh
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_cacheDuration, (_) {
      refreshNotifications();
    });
  }

  // Stop periodic refresh
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Refresh notifications if needed
  Future<void> refreshNotifications() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final notifications = await _fetchNotificationsFromServer();
      if (notifications != null) {
        _cachedNotifications = _deduplicateNotifications(notifications);
        _lastFetchTime = DateTime.now();
        notifyListeners();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // Deduplicate notifications based on report ID and timestamp
  List<Map<String, dynamic>> _deduplicateNotifications(
      List<Map<String, dynamic>> notifications) {
    final Map<String, Map<String, dynamic>> uniqueNotifications = {};

    for (var notification in notifications) {
      final report = notification['report'] as Map<String, dynamic>?;
      if (report == null) continue;

      final reportId = report['_id']?.toString();
      if (reportId == null) continue;

      final timestamp = notification['createdAt'] ?? notification['timestamp'];
      if (timestamp == null) continue;

      final key = '$reportId-$timestamp';

      // Only keep the latest notification for each report
      if (!uniqueNotifications.containsKey(key) ||
          DateTime.parse(timestamp).isAfter(
              DateTime.parse(uniqueNotifications[key]!['createdAt']))) {
        uniqueNotifications[key] = notification;
      }
    }

    return uniqueNotifications.values.toList();
  }

  // Fetch notifications from server
  Future<List<Map<String, dynamic>>?> _fetchNotificationsFromServer() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;

      final response = await _httpClient.get(
        '${Config.baseUrl}/api/v1/notifications',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawNotifications = jsonDecode(response.body);
        return rawNotifications.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return null;
    }
  }

  // Public method to get notifications
  Future<List<Map<String, dynamic>>> fetchNotifications(
      BuildContext context) async {
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _cachedNotifications.isNotEmpty) {
      return _cachedNotifications;
    }

    // Otherwise fetch fresh notifications
    await refreshNotifications();
    return _cachedNotifications;
  }

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

  Future<void> clearUserNotifications() async {
    // Clear in-memory cache
    _cachedNotifications.clear();
    _lastFetchTime = null;
    // Clear SharedPreferences for notification keys
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) =>
            key.startsWith('notification_') || key == 'last_notification_view')
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    notifyListeners();
  }
}

// Retrieve the token from secure storage
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');
  print('Retrieved Token: $token');
  return token;
}
