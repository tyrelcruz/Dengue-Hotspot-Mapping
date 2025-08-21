import 'package:flutter/material.dart';

class NotificationPopup {
  // Reusable responsive dialog that prevents bottom overflow and supports optional image
  static void showCustom(
    BuildContext context, {
    required String title,
    required String message,
    Widget? image,
    String buttonText = 'OK',
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final media = MediaQuery.of(context);
        final maxHeight = media.size.height * 0.7; // cap dialog content height
        final maxWidth = media.size.width * 0.9;

        return AlertDialog(
          scrollable: true,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text(title),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: maxWidth,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image != null) ...[
                    // Keep image responsive and avoid overflow
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Limit image height relative to available space
                          final imgMaxHeight = maxHeight * 0.35;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: imgMaxHeight,
                              maxWidth: constraints.maxWidth,
                            ),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: image,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static void showUnderReview(BuildContext context) {
    showCustom(
      context,
      title: 'Report Under Review',
      message:
          'This report is currently being reviewed by our team. Please check back later for updates.',
    );
  }

  static void showReportDeleted(BuildContext context) {
    showCustom(
      context,
      title: 'Report Deleted',
      message: 'This report has been deleted and is no longer available.',
    );
  }

  static void showReportRejected(BuildContext context) {
    showCustom(
      context,
      title: 'Report Rejected',
      message:
          'This report has been rejected. Please check the details for more information.',
    );
  }
}
