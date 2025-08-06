import 'package:flutter/material.dart';

class LocationNotification extends StatefulWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onDismiss;

  const LocationNotification({
    Key? key,
    required this.title,
    required this.message,
    required this.backgroundColor,
    this.duration = const Duration(seconds: 5),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<LocationNotification> createState() => _LocationNotificationState();
}

class _LocationNotificationState extends State<LocationNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location icon
                      Container(
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
                      const SizedBox(width: 12),
                      // Text content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dismiss button (moved here)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class to show the notification
class LocationNotificationService {
  static OverlayEntry? _currentNotification;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Remove any existing notification
    _currentNotification?.remove();

    // Create new notification
    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        right: 0,
        child: LocationNotification(
          title: title,
          message: message,
          backgroundColor: backgroundColor,
          duration: duration,
          onDismiss: () {
            _currentNotification?.remove();
            _currentNotification = null;
          },
        ),
      ),
    );

    // Show the notification
    Overlay.of(context).insert(_currentNotification!);
  }

  static void dismiss() {
    _currentNotification?.remove();
    _currentNotification = null;
  }
}
