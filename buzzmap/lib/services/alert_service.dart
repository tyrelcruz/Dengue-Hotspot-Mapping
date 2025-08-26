import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:buzzmap/config/config.dart';
import 'package:buzzmap/services/http_client.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final _alertController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;

  final _httpClient = HttpClient();
  Timer? _pollingTimer;
  Map<String, dynamic>? _lastAlert;
  bool _isPolling = false;
  bool _isInitialLoad = true;

  void startPolling() {
    if (_isPolling) return;

    debugPrint('Starting alert polling...');
    debugPrint('Using base URL: ${Config.baseUrl}');

    _isPolling = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchLatestAlert();
    });
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

      final response = await _httpClient.get(url);

      debugPrint('Alert response status: ${response.statusCode}');
      debugPrint('Alert response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          final latestAlert = data['data'][0];
          debugPrint('Latest alert: $latestAlert');

          if (_lastAlert == null || _lastAlert!['_id'] != latestAlert['_id']) {
            _lastAlert = latestAlert;

            if (!_isInitialLoad) {
              debugPrint('New alert detected! Broadcasting...');
              final formattedAlert = {
                'messages': latestAlert['messages'] ?? [],
                'severity': latestAlert['severity'],
                'barangays': latestAlert['barangays'] ?? [],
              };
              debugPrint('Formatted alert for UI: $formattedAlert');
              _alertController.add(formattedAlert);
            } else {
              debugPrint('Initial load - not broadcasting alert');
              _isInitialLoad = false;
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
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      debugPrint('Error type: ${e.runtimeType}');
    }
  }

  void dispose() {
    stopPolling();
    _alertController.close();
  }

  void showAlert(Map<String, dynamic> alert) {
    final formattedAlert = {
      'messages': alert['messages'] ?? [],
      'severity': alert['severity'],
      'barangays': alert['barangays'] ?? [],
    };
    _alertController.add(formattedAlert);
  }
}
