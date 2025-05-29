import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  final String currentRoute;

  const MenuScreen({super.key, required this.currentRoute});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
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
              child: SvgPicture.asset(
                'assets/icons/logo_ligthbg.svg',
                height: 80,
              ),
            ),
            const SizedBox(height: 5),
            _buildMenuButton(context, 'Home', '/', theme),
            _buildMenuButton(context, 'Mapping', '/mapping', theme),
            _buildMenuButton(context, 'Community', '/community', theme),
            _buildMenuButton(context, 'Prevention', '/prevention', theme),
            _buildMenuButton(context, 'About', '/about', theme),

            const Spacer(),

            // Separate Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, String route, ThemeData theme) {
    final bool isActive = widget.currentRoute == route;

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

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Koulen',
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _handleLogout,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }
}
