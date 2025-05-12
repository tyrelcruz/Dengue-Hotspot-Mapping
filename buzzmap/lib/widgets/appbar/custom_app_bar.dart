import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/pages/menu_screen.dart';
import 'package:buzzmap/pages/notification_screen.dart';
import 'package:buzzmap/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String currentRoute;
  final String themeMode;
  final String? bannerTitle; // Optional banner title
  final VoidCallback? onBannerClose; // Optional callback for the X icon

  const CustomAppBar({
    super.key,
    required this.title,
    required this.currentRoute,
    this.themeMode = "light",
    this.bannerTitle,
    this.onBannerClose,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(56.0 + (bannerTitle != null ? 50.0 : 0.0));
}

class _CustomAppBarState extends State<CustomAppBar> {
  int _unreadCount = 0;
  bool _isLoading = true;
  Timer? _refreshTimer;
  static const String _lastViewedKey = 'last_notification_view';

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Set up periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateLastViewedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc();
    await prefs.setString(_lastViewedKey, now.toIso8601String());
    print('📅 Updated last viewed time: $now');
    // Immediately update the count after setting the last viewed time
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedStr = prefs.getString(_lastViewedKey);
      final lastViewed = lastViewedStr != null
          ? DateTime.parse(lastViewedStr).toUtc()
          : DateTime.now().toUtc().subtract(
              const Duration(days: 365)); // Default to old date if never viewed

      final notifications =
          await NotificationService().fetchNotifications(context);
      if (!mounted) return;

      setState(() {
        // Count notifications that are newer than the last viewed time
        _unreadCount = notifications.where((n) {
          try {
            // Try to get the timestamp from the notification
            final timestamp =
                n['timestamp'] ?? n['createdAt'] ?? n['created_at'];
            if (timestamp == null) return false;

            final notificationDate =
                DateTime.parse(timestamp.toString()).toUtc();
            final status = n['status']?.toString().toLowerCase();

            // Count notifications that are newer than last viewed and not archived
            final isNewer = notificationDate.isAfter(lastViewed);
            print(
                '📅 Notification date: $notificationDate, Last viewed: $lastViewed, Is newer: $isNewer');
            return isNewer && status != 'archived';
          } catch (e) {
            print('❌ Error parsing notification date: $e');
            return false;
          }
        }).length;
        _isLoading = false;
      });

      print('📊 Unread notifications count: $_unreadCount');
      print('⏰ Last viewed: $lastViewed');
    } catch (e) {
      print('❌ Error loading notification count: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = widget.themeMode == "dark";

    final Color backgroundColor =
        isDarkMode ? theme.colorScheme.primary : Colors.white;
    final Color textColor =
        isDarkMode ? Colors.white : theme.colorScheme.primary;
    final Color iconColor = textColor;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isDarkMode
                ? 'assets/icons/logo_darkbg.svg'
                : 'assets/icons/logo_ligthbg.svg',
            width: 45,
            height: 45,
          ),
          const SizedBox(width: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'BUZZ',
                  style: TextStyle(
                    fontFamily: 'Koulen',
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    fontSize: 37,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'MAP',
                  style: TextStyle(
                    fontFamily: 'Koulen',
                    fontStyle: FontStyle.italic,
                    color:
                        isDarkMode ? Colors.white : theme.colorScheme.surface,
                    fontSize: 37,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/notif.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              onPressed: () async {
                // Update last viewed time before navigating
                await _updateLastViewedTime();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
                // Reload unread count when returning from notification screen
                _loadUnreadCount();
              },
            ),
            if (!_isLoading && _unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.menu, size: 32, color: iconColor),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return MenuScreen(currentRoute: widget.currentRoute);
                },
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var slideTween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var slideAnimation = animation.drive(slideTween);
                  var fadeTween = Tween<double>(begin: 1.0, end: 0.0);
                  var fadeAnimation = animation.drive(fadeTween);

                  return FadeTransition(
                    opacity: secondaryAnimation.drive(fadeTween),
                    child:
                        SlideTransition(position: slideAnimation, child: child),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      // Optional banner below the AppBar
      bottom: widget.bannerTitle != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(50.0),
              child: Container(
                height: 40.0,
                color: theme.colorScheme.primary, // Banner background color
                child: Row(
                  children: [
                    // X icon inside a white circle
                    IconButton(
                      onPressed: () {
                        if (widget.onBannerClose != null) {
                          widget.onBannerClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: Container(
                        width: 21,
                        height: 21,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/close.svg',
                            color: theme.colorScheme.primary,
                            width: 10,
                            height: 10,
                          ),
                        ),
                      ),
                    ),
                    // Centered title
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.bannerTitle!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Spacer to balance the layout (adjust width as needed)
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
