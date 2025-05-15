import 'dart:io';

class Config {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }
}
