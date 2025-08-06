import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:upgrader/upgrader.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static Future<void> checkForUpdates(BuildContext context) async {
    final upgrader = Upgrader(
      debugDisplayAlways: true,
      debugLogging: true,
      showIgnore: false,
      showLater: true,
      canDismissDialog: false,
      shouldPopScope: () => false,
    );

    // The upgrader will automatically check for updates when initialized
    upgrader.initialize();
  }

  static Future<String> getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
