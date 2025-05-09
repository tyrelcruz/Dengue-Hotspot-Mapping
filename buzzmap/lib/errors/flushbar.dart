import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

/// A utility class that provides globally accessible FlushBar notifications
/// throughout the Flutter application.
class AppFlushBar {
  /// Shows a success message FlushBar.
  static Future<void> showSuccess(
    BuildContext context, {
    String title = 'Success',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return _showFlushBar(
      context,
      title: title,
      message: message,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }

  /// Shows an error message FlushBar.
  static Future<void> showError(
    BuildContext context, {
    String title = 'Failed',
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return _showFlushBar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFB8585B),
      duration: duration,
    );
  }

  /// Shows a network error message FlushBar.
  static Future<void> showNetworkError(
    BuildContext context, {
    String title = '🛜 Network Error',
    String message = 'Something went wrong. Please check your connection.',
    Duration duration = const Duration(seconds: 3),
  }) {
    return _showFlushBar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color.fromARGB(255, 88, 96, 184),
      duration: duration,
    );
  }

  /// Shows a custom message FlushBar with specified parameters.
  static Future<void> showCustom(
    BuildContext context, {
    required String title,
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    return Flushbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
      icon: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      shouldIconPulse: false,
      flushbarPosition: FlushbarPosition.TOP,
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      mainButton: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'DISMISS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ).show(context);
  }

  /// Shows an empathetic feedback message (special for your use case).
  static Future<void> showEmpatheticFeedback(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    return _showFlushBar(
      context,
      title: 'Thank You for Reporting!',
      message: message,
      backgroundColor: Colors.green, // Using a more positive color like green
      duration: duration,
    );
  }

  /// Private method to show FlushBar with the specified parameters.
  static Future<void> _showFlushBar(
    BuildContext context, {
    String? title,
    required String message,
    required Color backgroundColor,
    required Duration duration,
  }) {
    return Flushbar(
      title: title,
      titleText: title != null
          ? Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFFFEFEFE),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      message: message,
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16.0,
          color: Color(0xFFFEFEFE),
          fontWeight: FontWeight.w500,
        ),
      ),
      boxShadows: const [
        BoxShadow(
          color: Colors.grey,
          blurRadius: 5,
        )
      ],
      duration: duration,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 26.0),
      margin: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(8.0),
      backgroundColor: backgroundColor,
      flushbarPosition: FlushbarPosition.TOP,
      forwardAnimationCurve: Curves.easeOut,
    ).show(context);
  }
}
