import 'dart:io' show Platform;

class Config {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      if (Platform.environment.containsKey('ANDROID_EMULATOR')) {
        return 'http://10.0.2.2:4000'; // Android emulator
      }
      return 'http://192.168.1.45:4000'; // Physical Android device
    } else if (Platform.isIOS) {
      if (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME')) {
        return 'http://localhost:4000'; // iOS simulator
      }
      return 'http://192.168.1.45:4000'; // Physical iOS device
    }
    return 'http://localhost:4000'; // Default fallback
  }

  // HTTP request timeout duration
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
