import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final _alertController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;

  Timer? _pollingTimer;
  Map<String, dynamic>? _lastAlert;
  bool _isPolling = false;
  bool _isInitialLoad = true;  // Add flag to track initial load

  void startPolling() {
    if (_isPolling) return;
    
    debugPrint('Starting alert polling...');
    debugPrint('Using base URL: ${Config.baseUrl}');
    
    _isPolling = true;
    // Poll every 5 seconds instead of 30 for testing
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLatestAlert();
    });
    // Initial fetch
    _fetchLatestAlert();
  }

  void stopPolling() {
    debugPrint('Stopping alert polling...');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  Future<void> _fetchLatestAlert() async {
    try {
      final url = '${Config.baseUrl}/api/v1/alerts';
      debugPrint('Fetching latest alert from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      debugPrint('Alert response status: ${response.statusCode}');
      debugPrint('Alert response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data'].isNotEmpty) {
          // Get the most recent alert
          final latestAlert = data['data'][0];
          debugPrint('Latest alert: $latestAlert');
          
          // Check if this is a new alert
          if (_lastAlert == null || _lastAlert!['_id'] != latestAlert['_id']) {
            _lastAlert = latestAlert;
            
            // Only broadcast if it's not the initial load
            if (!_isInitialLoad) {
              debugPrint('New alert detected! Broadcasting...');
              // Format the alert data for the UI
              final formattedAlert = {
                'messages': latestAlert['messages'] ?? [],
                'severity': latestAlert['severity'],
                'barangays': latestAlert['barangays'] ?? [],
              };
              
              debugPrint('Formatted alert for UI: $formattedAlert');
              _alertController.add(formattedAlert);
            } else {
              debugPrint('Initial load - not broadcasting alert');
              _isInitialLoad = false;  // Set to false after first load
            }
          } else {
            debugPrint('No new alerts');
          }
        } else {
          debugPrint('No alerts in response data or success is false');
          debugPrint('Response data: $data');
        }
      } else {
        debugPrint('Failed to fetch alerts: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
      }
    } on TimeoutException {
      debugPrint('Request timed out while fetching alerts');
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is http.ClientException) {
        debugPrint('Network error: ${e.message}');
      }
    }
  }

  void dispose() {
    stopPolling();
    _alertController.close();
  }
} 