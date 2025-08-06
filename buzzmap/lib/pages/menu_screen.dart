import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/pages/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';

class MenuScreen extends StatefulWidget {
  final String currentRoute;

  const MenuScreen({super.key, required this.currentRoute});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _username;
  String? _email;
  String? _profilePhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? 'User';
        _email = prefs.getString('email') ?? 'user@email.com';
        _profilePhotoUrl = prefs.getString('profilePhotoUrl');
        _isLoading = false;
      });

      // If no profile photo URL in SharedPreferences, fetch from server
      if (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty) {
        await _fetchProfilePhotoUrl();
      }
    } catch (e) {
      print('Error loading user info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProfilePhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photoUrl = data['user']?['profilePhotoUrl'];

        if (photoUrl != null && photoUrl.isNotEmpty) {
          print('Debug: Fetched profile photo URL from server: $photoUrl');
          await prefs.setString('profilePhotoUrl', photoUrl);
          setState(() {
            _profilePhotoUrl = photoUrl;
          });
        }
      } else {
        print(
            'Debug: Failed to fetch profile photo URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Debug: Error fetching profile photo URL: $e');
    }
  }

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

            // Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 8),
            // User info and logout row (dynamic)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
              child: FutureBuilder<Map<String, String>>(
                future: _getUserInfo(),
                builder: (context, snapshot) {
                  final username = snapshot.data?['username'] ?? 'User';
                  final email = snapshot.data?['email'] ?? 'user@email.com';
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(context); // Close the menu
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(username: username, email: email),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber[200],
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : _profilePhotoUrl != null &&
                                      _profilePhotoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _profilePhotoUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print(
                                              'Debug: Image loading error: $error');
                                          return const Icon(Icons.person,
                                              size: 40, color: Colors.grey);
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const CircularProgressIndicator();
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        // Name and email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A334B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF38546B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Logout icon button
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.redAccent, size: 32),
                          onPressed: _handleLogout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    // Try both 'username' and 'name' keys, fallback to email if both are missing
    String? username = prefs.getString('username');
    String? name = prefs.getString('name');
    String? email = prefs.getString('email');
    String displayName = (username != null && username.isNotEmpty)
        ? username
        : (name != null && name.isNotEmpty)
            ? name
            : (email ?? 'User');
    return {
      'username': displayName,
      'email': email ?? 'user@email.com',
    };
  }
}
