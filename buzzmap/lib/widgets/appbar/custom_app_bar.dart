import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/pages/menu_screen.dart';
import 'package:buzzmap/pages/notification_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = themeMode == "dark";

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
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notif.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationScreen()),
            );
          },
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
                  return MenuScreen(currentRoute: currentRoute);
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
      bottom: bannerTitle != null
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
                        if (onBannerClose != null) {
                          onBannerClose!();
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
                          bannerTitle!,
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

  @override
  Size get preferredSize =>
      Size.fromHeight(56.0 + (bannerTitle != null ? 50.0 : 0.0));
}
