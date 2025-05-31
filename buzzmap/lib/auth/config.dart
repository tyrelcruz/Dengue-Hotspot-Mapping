import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Login
class Config {
  static String get baseUrl {
    return 'https://buzzmap-server.vercel.app';
  }

  // Add these URLs
  static String get verifyOtpUrl => '$baseUrl/api/v1/otp/verify';
  static String get resendOtpUrl => '$baseUrl/api/v1/otp/request';
  static String get googleLoginUrl => '$baseUrl/api/v1/auth/google-login';
  static String get createPostUrl => '$baseUrl/api/v1/reports';
  static String get createPostwImageUrl => '$baseUrl/api/v1/posts';
  static String get userProfileUrl => '$baseUrl/api/v1/auth/me';

  // Google Sign-In Configuration
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleClientSecret =>
      dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';

  // Image Upload Configuration
  static String get imgbbApiKey => dotenv.env['IMGBB_API_KEY'] ?? '';

  // API Timeouts and Retries
  static Duration get timeoutDuration => Duration(
        seconds: int.parse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '10'),
      );
  static int get maxRetries => int.parse(dotenv.env['API_MAX_RETRIES'] ?? '3');
  static Duration get retryDelay => Duration(
        seconds: int.parse(dotenv.env['API_RETRY_DELAY_SECONDS'] ?? '2'),
      );
}
