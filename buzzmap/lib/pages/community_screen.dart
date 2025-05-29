import 'package:buzzmap/main.dart';
import 'package:buzzmap/pages/post/post_screen.dart';
import 'package:buzzmap/widgets/announcement_card.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/widgets/custom_search_bar.dart';
import 'package:buzzmap/widgets/custom_tab_bar.dart';
import 'package:buzzmap/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/widgets/post_detail_screen.dart';
import 'package:buzzmap/errors/flushbar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _allPosts = [];
  bool _isLoading = true;
  bool _isUsernameLoading = true;
  late SharedPreferences _prefs;
  String? _currentUsername;
  Position? _currentPosition;
  bool _isLocationLoading = false;

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _loadReports();
    _getCurrentLocation();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      String? username = _prefs.getString('username');
      String? email = _prefs.getString('email');
      String? userId = _prefs.getString('userId');
      print(
          '👤 Loading username from SharedPreferences: $username'); // Debug log
      print('📧 Loading email from SharedPreferences: $email'); // Debug log
      print('👤 Loading userId from SharedPreferences: $userId'); // Debug log

      if (username == null ||
          username.isEmpty ||
          email == null ||
          email.isEmpty ||
          userId == null ||
          userId.isEmpty) {
        // Fetch from backend if missing
        final token = _prefs.getString('authToken');
        if (token != null && token.isNotEmpty) {
          try {
            final response = await http.get(
              Uri.parse(Config.userProfileUrl),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              // Try both 'username' and 'name' keys
              final fetchedUsername = data['username'] ?? data['name'] ?? '';
              final fetchedEmail = data['email'] ?? '';
              final fetchedUserId = data['_id'] ?? '';
              if (fetchedUsername.isNotEmpty) {
                username = fetchedUsername;
                await _prefs.setString('username', fetchedUsername);
                print(
                    '👤 Username fetched from backend and saved: $fetchedUsername');
              }
              if (fetchedEmail.isNotEmpty) {
                email = fetchedEmail;
                await _prefs.setString('email', fetchedEmail);
                print('📧 Email fetched from backend and saved: $fetchedEmail');
              }
              if (fetchedUserId.isNotEmpty) {
                userId = fetchedUserId;
                await _prefs.setString('userId', fetchedUserId);
                print(
                    '👤 User ID fetched from backend and saved: $fetchedUserId');
              }
            } else {
              print('❌ Failed to fetch user profile: ${response.body}');
            }
          } catch (e) {
            print('❌ Error fetching user profile: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _currentUsername = username;
          _isUsernameLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading username: $e');
      if (mounted) {
        setState(() {
          _isUsernameLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final currentUserId = prefs.getString('userId');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/v1/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Process reports in parallel
      final reports = await Future.wait(
        data
            .where((report) => report['status'] == 'Validated')
            .map((report) async {
          final DateTime reportDate = DateTime.parse(report['date_and_time']);
          final DateTime now = DateTime.now();
          final Duration difference = now.difference(reportDate);

          String whenPosted;
          if (difference.inDays > 0) {
            whenPosted = '${difference.inDays} days ago';
          } else if (difference.inHours > 0) {
            whenPosted = '${difference.inHours} hours ago';
          } else if (difference.inMinutes > 0) {
            whenPosted = '${difference.inMinutes} minutes ago';
          } else {
            whenPosted = 'Just now';
          }

          final username = report['user']?['username'] ?? 'Anonymous';
          final email = report['user']?['email'] ?? '';
          final userId = report['user']?['_id'] ?? '';

          return {
            'id': report['_id'],
            'username': username,
            'email': email,
            'userId': userId,
            'whenPosted': whenPosted,
            'location': '${report['barangay']}, Quezon City',
            'barangay': report['barangay'],
            'date': '${reportDate.month}/${reportDate.day}/${reportDate.year}',
            'time':
                '${reportDate.hour.toString().padLeft(2, '0')}:${reportDate.minute.toString().padLeft(2, '0')}',
            'reportType': report['report_type'],
            'description': report['description'],
            'images': report['images'] != null
                ? List<String>.from(report['images'])
                : <String>[],
            'iconUrl': 'assets/icons/person_1.svg',
            'status': report['status'],
            'numUpvotes': report['upvotes']?.length ?? 0,
            'numDownvotes': report['downvotes']?.length ?? 0,
            'date_and_time': report['date_and_time'],
            'specific_location': report['specific_location'],
          };
        }),
      );

      return reports;
    } else {
      throw Exception('Failed to load reports');
    }
  }

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await fetchReports();
      if (mounted) {
        setState(() {
          _allPosts = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppFlushBar.showError(
          context,
          title: 'Loading Failed',
          message: 'Unable to load reports. Please try again.',
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them to use the "Near Me" feature.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Location permissions are required to use the "Near Me" feature.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable them in app settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Current Location: ${position.latitude}, ${position.longitude}');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get your location. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  List<Map<String, dynamic>> get _currentPosts {
    final query = _searchQuery.toLowerCase();
    var filtered = _allPosts.where((post) {
      return post['username'].toLowerCase().contains(query) ||
          post['description'].toLowerCase().contains(query) ||
          post['reportType'].toLowerCase().contains(query) ||
          post['barangay'].toLowerCase().contains(query);
    }).toList();

    // Apply sorting based on selected tab
    if (selectedIndex == 0) {
      // Popular tab
      filtered.sort(
          (a, b) => (b['numUpvotes'] as int).compareTo(a['numUpvotes'] as int));
    } else if (selectedIndex == 1) {
      // Latest tab
      filtered.sort((a, b) => (b['date_and_time'] as String)
          .compareTo(a['date_and_time'] as String));
    } else if (selectedIndex == 2) {
      // My Posts tab
      final currentUserId = _prefs.getString('userId');
      if (currentUserId == null || currentUserId.isEmpty) {
        return [];
      }
      filtered =
          _allPosts.where((post) => post['userId'] == currentUserId).toList();
      filtered.sort((a, b) => (b['date_and_time'] as String)
          .compareTo(a['date_and_time'] as String));
    } else if (selectedIndex == 3) {
      // Near Me tab
      if (_currentPosition == null) {
        print('❌ Current position is null');
        return [];
      }

      print('🔍 Total posts before filtering: ${filtered.length}');

      // Add distance to each post and filter by radius
      filtered = filtered.map((post) {
        final coords = post['specific_location']?['coordinates'];
        print('📍 Post coordinates: $coords');

        if (coords != null && coords.length == 2) {
          final distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            coords[1],
            coords[0],
          );
          print('📏 Distance to post: ${distance.toStringAsFixed(2)}km');
          return {...post, 'distance': distance};
        }
        print('⚠️ Post has no valid coordinates');
        return {...post, 'distance': double.infinity};
      }).toList();

      // Sort by distance
      filtered.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Filter out posts that are too far (more than 2km radius)
      filtered = filtered
          .where((post) => (post['distance'] as double) <= 2.0)
          .toList();

      print('🔍 Posts within 2km radius: ${filtered.length}');
    }

    return filtered;
  }

  Future<void> _reportPost(Map<String, dynamic> post) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${post['id']}/report'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to report post');
      }
    } catch (e) {
      print('Error reporting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to report post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${post['id']}'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _allPosts.removeWhere((p) => p['id'] == post['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Community',
        currentRoute: '/community',
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _initializePrefs();
              await _loadReports();
              await _getCurrentLocation();
            },
            edgeOffset: 80,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomSearchBar(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _showSuggestions = value.isNotEmpty;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomTabBar(
                          label: 'Popular',
                          isSelected: selectedIndex == 0,
                          onTap: () => _onTabSelected(0),
                        ),
                        CustomTabBar(
                          label: 'Latest',
                          isSelected: selectedIndex == 1,
                          onTap: () => _onTabSelected(1),
                        ),
                        CustomTabBar(
                          label: 'My Posts',
                          isSelected: selectedIndex == 2,
                          onTap: () => _onTabSelected(2),
                        ),
                        CustomTabBar(
                          label: 'Near Me',
                          isSelected: selectedIndex == 3,
                          onTap: () {
                            if (_currentPosition == null) {
                              _getCurrentLocation();
                            }
                            _onTabSelected(3);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedIndex == 0 || selectedIndex == 1) ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'STAY ',
                            style: theme.textTheme.displayLarge
                                ?.copyWith(color: theme.colorScheme.primary),
                          ),
                          TextSpan(
                            text: 'AHEAD ',
                            style: theme.textTheme.displayLarge
                                ?.copyWith(color: customColors?.surfaceDark),
                          ),
                          TextSpan(
                            text: 'OF DENGUE',
                            style: theme.textTheme.displayLarge
                                ?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-Time Dengue Updates from the Community.',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 18),
                    AnnouncementCard(
                      onRefresh: () {
                        // Refresh the reports when announcement is refreshed
                        _loadReports();
                      },
                    ),
                  ],
                  if (_isLoading || _isUsernameLoading || _isLocationLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_currentPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No reports available yet."),
                    )
                  else
                    ..._currentPosts.map((post) {
                      final isOwner =
                          post['userId'] == _prefs.getString('userId');
                      print('👤 Post username: \\${post['username']}');
                      print('👤 Post userId: \\${post['userId']}');
                      print(
                          '👤 Current userId: \\${_prefs.getString('userId')}');
                      print('🔒 Is owner: \\${isOwner}');
                      print('🔍 Post data: \\${post}'); // Debug log

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: post),
                            ),
                          );
                          setState(
                              () {}); // Refresh EngagementRow/comment count
                        },
                        child: PostCard(
                          key: ValueKey(
                              post['id']), // Ensure unique key for rebuild
                          post: post,
                          username: post['username'],
                          whenPosted: post['whenPosted'],
                          location: post['location'],
                          date: post['date'],
                          time: post['time'],
                          reportType: post['reportType'],
                          description: post['description'],
                          numUpvotes: post['numUpvotes'] ?? 0,
                          numDownvotes: post['numDownvotes'] ?? 0,
                          images: List<String>.from(post['images']),
                          iconUrl: post['iconUrl'],
                          type: 'bordered',
                          onReport: () => _reportPost(post),
                          onDelete: () => _deletePost(post),
                          isOwner: isOwner,
                          postId: post['id'],
                          showDistance: selectedIndex ==
                              3, // Show distance in Near Me tab
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          if (_showSuggestions)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (context) {
                      final query = _searchQuery.toLowerCase();
                      final suggestions = _allPosts
                          .where((post) =>
                              post['username'].toLowerCase().contains(query) ||
                              post['barangay'].toLowerCase().contains(query) ||
                              post['reportType']
                                  .toLowerCase()
                                  .contains(query) ||
                              post['description'].toLowerCase().contains(query))
                          .take(5)
                          .toList();

                      if (suggestions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No matches found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView(
                        shrinkWrap: true,
                        children: suggestions
                            .map((post) => ListTile(
                                  title: Text(post['description']),
                                  subtitle: Text(
                                    '👤 ${post['username']} · 📍 ${post['barangay']} · ⚠️ ${post['reportType']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _searchController.text =
                                          post['description'];
                                      _searchQuery = post['description'];
                                      _showSuggestions = false;
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 5,
            right: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(248, 169, 0, 1),
                    theme.colorScheme.secondary,
                  ],
                  stops: const [0.0, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 40,
                width: 160,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/prevention');
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prevention Tips',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/right_arrow.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 55,
            right: 3,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(248, 169, 0, 1),
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostScreen(),
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  'assets/icons/add.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
