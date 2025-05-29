import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      if (Platform.environment.containsKey('ANDROID_EMULATOR')) {
        return dotenv.env['API_BASE_URL_ANDROID_EMULATOR'] ??
            'http://10.0.2.2:4000';
      }
      return dotenv.env['API_BASE_URL_PHYSICAL_DEVICE'] ??
          'http://192.168.1.45:4000';
    } else if (Platform.isIOS) {
      if (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
        return dotenv.env['API_BASE_URL_IOS_SIMULATOR'] ??
            'http://localhost:4000';
      }
      return dotenv.env['API_BASE_URL_PHYSICAL_DEVICE'] ??
          'http://192.168.1.45:4000';
    }
    return dotenv.env['API_BASE_URL_IOS_SIMULATOR'] ?? 'http://localhost:4000';
  }

  // HTTP request timeout duration
  static Duration get timeoutDuration => Duration(
        seconds: int.parse(
          dotenv.env['API_TIMEOUT_SECONDS'] ?? '10',
        ),
      );

  // Retry configuration
  static int get maxRetries => int.parse(
        dotenv.env['API_MAX_RETRIES'] ?? '3',
      );
  static Duration get retryDelay => Duration(
        seconds: int.parse(
          dotenv.env['API_RETRY_DELAY_SECONDS'] ?? '2',
        ),
      );
}
