import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MenuScreen extends StatelessWidget {
  final String currentRoute;

  const MenuScreen({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 5, 0, 0),
              child:
                  SvgPicture.asset('assets/icons/logo_ligthbg.svg', height: 80),
            ),
            const SizedBox(height: 5),
            _buildMenuButton(context, 'Home', '/', theme),
            _buildMenuButton(context, 'Mapping', '/mapping', theme),
            _buildMenuButton(context, 'Community', '/community', theme),
            _buildMenuButton(context, 'Prevention', '/prevention', theme),
            _buildMenuButton(context, 'About', '/about', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, String route, ThemeData theme) {
    final bool isActive = currentRoute == route;

    return TextButton(
      onPressed: () {
        Navigator.pop(context);
        if (!isActive) {
          Navigator.pushNamed(context, route == '/' ? '/home' : route);
        }
      },
      child: Text(
        title,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.normal,
          fontFamily: 'Koulen',
          color: isActive
              ? theme.colorScheme.secondary
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}
