class UpdateConfig {
  // Your app's bundle ID/package name
  static const String androidPackageName = 'com.example.buzzmap';
  static const String iosBundleId = 'com.example.buzzmap';

  // Update check intervals (in seconds)
  static const int updateCheckInterval = 86400; // Check once per day

  // Minimum supported version
  static const String minimumSupportedVersion = '1.0.0';

  // Update server URLs
  static const String updateServerUrl = 'https://your-update-server.com';
  static const String androidUpdateUrl = '$updateServerUrl/android';
  static const String iosUpdateUrl = '$updateServerUrl/ios';
}
