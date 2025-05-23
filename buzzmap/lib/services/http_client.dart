import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:buzzmap/config/config.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _retry(() => http
        .get(
          Uri.parse(url),
          headers: headers,
        )
        .timeout(Config.timeoutDuration));
  }

  Future<http.Response> post(String url,
      {Map<String, String>? headers, Object? body}) async {
    return _retry(() => http
        .post(
          Uri.parse(url),
          headers: headers,
          body: body,
        )
        .timeout(Config.timeoutDuration));
  }

  Future<http.Response> put(String url,
      {Map<String, String>? headers, Object? body}) async {
    return _retry(() => http
        .put(
          Uri.parse(url),
          headers: headers,
          body: body,
        )
        .timeout(Config.timeoutDuration));
  }

  Future<http.Response> delete(String url,
      {Map<String, String>? headers, Object? body}) async {
    return _retry(() => http
        .delete(
          Uri.parse(url),
          headers: headers,
          body: body,
        )
        .timeout(Config.timeoutDuration));
  }

  Future<T> _retry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < Config.maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts == Config.maxRetries) {
          rethrow;
        }
        await Future.delayed(Config.retryDelay);
      }
    }
    throw Exception('Failed after ${Config.maxRetries} attempts');
  }
}
