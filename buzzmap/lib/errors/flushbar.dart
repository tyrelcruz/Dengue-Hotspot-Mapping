import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Future<void> showCustomizeFlushbar(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFFB8585B), // Default: error red
}) {
  return Flushbar(
    messageText: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16.0,
        color: Color(0xFFFEFEFE),
        fontWeight: FontWeight.bold,
      ),
    ),
    boxShadows: const [
      BoxShadow(
        color: Colors.grey,
        blurRadius: 5,
      )
    ],
    duration: const Duration(seconds: 3),
    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 26.0),
    margin: const EdgeInsets.all(10),
    borderRadius: BorderRadius.circular(8.0),
    backgroundColor: backgroundColor,
    flushbarPosition: FlushbarPosition.TOP,
    forwardAnimationCurve: Curves.easeOut,
  ).show(context);
}
