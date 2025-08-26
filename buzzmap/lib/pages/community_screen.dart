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
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:buzzmap/providers/post_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:buzzmap/providers/vote_provider.dart';
import 'package:buzzmap/errors/flushbar.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with RouteAware {
  int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSuggestions = false;
  bool _isUsernameLoading = true;
  late SharedPreferences _prefs;
  String? _currentUsername;
  Position? _currentPosition;
  bool _isLocationLoading = false;
  bool _hasShownLocationError = false;
  bool _isGettingLocation =
      false; // Prevent multiple simultaneous location calls
  RouteObserver<PageRoute>? _routeObserver;
  String _myPostsStatusFilter = 'All';

  // Add a map to store userId -> profilePhotoUrl
  Map<String, String> _userProfilePhotos = {};

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _getCurrentLocation(showErrors: false); // Don't show errors on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureProfilePhotoLoaded();
      await _fetchUserProfiles();
      await Provider.of<PostProvider>(context, listen: false)
          .fetchPosts(forceRefresh: true);
      // Use lazy loading instead of refreshAllVotes
      await Provider.of<VoteProvider>(context, listen: false)
          .loadVoteStatesIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes only once
    if (_routeObserver == null) {
      _routeObserver = ModalRoute.of(context)
          ?.navigator
          ?.widget
          .observers
          .whereType<RouteObserver<PageRoute>>()
          .firstOrNull;
      _routeObserver?.subscribe(this, ModalRoute.of(context)! as PageRoute);
    }
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      String? username = _prefs.getString('username');
      String? email = _prefs.getString('email');
      String? userId = _prefs.getString('userId');

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
              }
              if (fetchedEmail.isNotEmpty) {
                email = fetchedEmail;
                await _prefs.setString('email', fetchedEmail);
              }
              if (fetchedUserId.isNotEmpty) {
                userId = fetchedUserId;
                await _prefs.setString('userId', fetchedUserId);
              }
            } else {}
          } catch (e) {}
        }
      }

      if (mounted) {
        setState(() {
          _currentUsername = username;
          _isUsernameLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUsernameLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation({bool showErrors = true}) async {
    // Prevent multiple simultaneous location calls
    if (_isGettingLocation) return;

    _isGettingLocation = true;
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && showErrors && !_hasShownLocationError) {
          _hasShownLocationError = true;
          AppFlushBar.showError(
            context,
            title: 'Location Services Disabled',
            message:
                'Please enable location services to use the "Near Me" feature.',
          );
        }

        // For simulator testing, use a fallback location (Quezon City coordinates)
        if (mounted) {
          setState(() {
            _currentPosition = Position(
              latitude: 14.6760, // Quezon City latitude
              longitude: 121.0437, // Quezon City longitude
              timestamp: DateTime.now(),
              accuracy: 100.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
            _isLocationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && showErrors && !_hasShownLocationError) {
            _hasShownLocationError = true;
            AppFlushBar.showError(
              context,
              title: 'Location Permission Required',
              message:
                  'Location permissions are required to use the "Near Me" feature.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && showErrors && !_hasShownLocationError) {
          _hasShownLocationError = true;
          AppFlushBar.showError(
            context,
            title: 'Location Permission Denied',
            message:
                'Location permissions are permanently denied. Please enable them in app settings.',
          );
        }

        // For simulator testing, use a fallback location when permissions are denied
        if (mounted) {
          setState(() {
            _currentPosition = Position(
              latitude: 14.6760, // Quezon City latitude
              longitude: 121.0437, // Quezon City longitude
              timestamp: DateTime.now(),
              accuracy: 100.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
            _isLocationLoading = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.medium, // Reduced accuracy for better performance
        timeLimit:
            const Duration(seconds: 10), // Add timeout to prevent hanging
      );

      // Location obtained successfully

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
          _hasShownLocationError = false; // Reset error flag on success
        });
      }
      _isGettingLocation = false;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
        if (showErrors && !_hasShownLocationError) {
          _hasShownLocationError = true;
          AppFlushBar.showError(
            context,
            title: 'Location Error',
            message: 'Failed to get your location. Please try again.',
          );
        }
      }
      _isGettingLocation = false;
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
    final posts = Provider.of<PostProvider>(context).posts;
    final query = _searchQuery.toLowerCase();
    var filtered = posts.where((post) {
      final username = post['username']?.toString().toLowerCase() ?? '';
      final description = post['description']?.toString().toLowerCase() ?? '';
      final reportType = post['reportType']?.toString().toLowerCase() ?? '';
      final barangay = post['barangay']?.toString().toLowerCase() ?? '';

      return username.contains(query) ||
          description.contains(query) ||
          reportType.contains(query) ||
          barangay.contains(query);
    }).toList();

    // Apply sorting based on selected tab
    if (selectedIndex == 0) {
      // Popular tab - Sort by total engagement (upvotes + comments - downvotes)
      // Show only validated/approved posts in public tabs
      filtered = filtered.where((p) {
        final s = (p['status']?.toString() ?? '').toLowerCase();
        return s == 'validated' || s == 'approved';
      }).toList();
      filtered.sort((a, b) {
        final aUpvotes = (a['numUpvotes'] as int?) ?? 0;
        final aDownvotes = (a['numDownvotes'] as int?) ?? 0;
        final aComments = (a['_commentCount'] as int?) ?? 0;
        final bUpvotes = (b['numUpvotes'] as int?) ?? 0;
        final bDownvotes = (b['numDownvotes'] as int?) ?? 0;
        final bComments = (b['_commentCount'] as int?) ?? 0;

        // Calculate total engagement score (upvotes + comments - downvotes)
        final aScore = aUpvotes + aComments - aDownvotes;
        final bScore = bUpvotes + bComments - bDownvotes;

        // If scores are equal, sort by most recent
        if (aScore == bScore) {
          final aDate = DateTime.parse(a['date_and_time'] ?? '');
          final bDate = DateTime.parse(b['date_and_time'] ?? '');
          return bDate.compareTo(aDate);
        }

        return bScore.compareTo(aScore);
      });
    } else if (selectedIndex == 1) {
      // Latest tab
      // Show only validated/approved posts in public tabs
      filtered = filtered.where((p) {
        final s = (p['status']?.toString() ?? '').toLowerCase();
        return s == 'validated' || s == 'approved';
      }).toList();
      filtered.sort((a, b) => (b['date_and_time']?.toString() ?? '')
          .compareTo(a['date_and_time']?.toString() ?? ''));
    } else if (selectedIndex == 2) {
      // My Posts tab
      final currentUserId = _prefs.getString('userId');
      if (currentUserId == null || currentUserId.isEmpty) {
        return [];
      }
      filtered = posts
          .where((post) => post['userId']?.toString() == currentUserId)
          .toList();
      // Apply status filter even if there are no posts (UI shows filter regardless)
      if (_myPostsStatusFilter != 'All') {
        filtered = filtered.where((post) {
          final status = post['status']?.toString() ?? '';
          switch (_myPostsStatusFilter) {
            case 'Pending':
              return status == 'Pending';
            case 'Approved':
              return status == 'Approved' || status == 'Validated';
            case 'Rejected':
              return status == 'Rejected';
          }
          return true;
        }).toList();
      }
      filtered.sort((a, b) => (b['date_and_time']?.toString() ?? '')
          .compareTo(a['date_and_time']?.toString() ?? ''));
    } else if (selectedIndex == 3) {
      // Near Me tab
      if (_currentPosition == null) {
        return [];
      }

      try {
        // Add distance to each post and filter by radius
        filtered = filtered.map((post) {
          try {
            final coords = post['specific_location']?['coordinates'];
            if (coords != null && coords is List && coords.length >= 2) {
              final lat = coords[1] is num ? coords[1].toDouble() : null;
              final lng = coords[0] is num ? coords[0].toDouble() : null;

              if (lat != null && lng != null) {
                try {
                  final distance = _calculateDistance(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    lat,
                    lng,
                  );
                  // Distance calculated successfully
                  return {...post, 'distance': distance};
                } catch (e) {
                  return {...post, 'distance': double.infinity};
                }
              }
            }
            return {...post, 'distance': double.infinity};
          } catch (e) {
            return {...post, 'distance': double.infinity};
          }
        }).toList();

        // Sort by distance
        filtered.sort((a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));

        // Filter out posts that are too far (more than 2km radius)
        filtered = filtered
            .where((post) => (post['distance'] as double) <= 2.0)
            .toList();

        // Near Me filtering complete
      } catch (e) {
        filtered = [];
      }
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
          // Assuming the post is removed from the provider's posts
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _ensureProfilePhotoLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    String? profilePhotoUrl = prefs.getString('profilePhotoUrl');
    final token = prefs.getString('authToken');
    if ((profilePhotoUrl == null || profilePhotoUrl.isEmpty) && token != null) {
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
            await prefs.setString('profilePhotoUrl', photoUrl);
          }
        }
      } catch (e) {}
    }
  }

  // Fetch all user profiles and map userId to profilePhotoUrl
  Future<void> _fetchUserProfiles() async {
    try {
      final response =
          await http.get(Uri.parse('${Config.baseUrl}/api/v1/accounts/basic'));
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          _userProfilePhotos = {
            for (var user in users)
              if (user['_id'] != null && user['profilePhotoUrl'] != null)
                user['_id']: user['profilePhotoUrl'] ?? ''
          };
        });
      } else {}
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context);

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
              await _ensureProfilePhotoLoaded();
              await _fetchUserProfiles();
              await postProvider.fetchPosts(forceRefresh: true);
              // Use lazy loading instead of refreshAllVotes
              await Provider.of<VoteProvider>(context, listen: false)
                  .loadVoteStatesIfNeeded();
              await _getCurrentLocation(
                  showErrors: false); // Don't show errors on refresh
            },
            edgeOffset: 10,
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
                              _getCurrentLocation(
                                  showErrors:
                                      true); // Show errors when user actively taps Near Me
                            }
                            _onTabSelected(3);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Show My Posts status filters whenever My Posts tab is active
                  if (selectedIndex == 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...['All', 'Pending', 'Approved', 'Rejected']
                                      .map((opt) {
                                    final active = _myPostsStatusFilter == opt;
                                    final primary =
                                        Theme.of(context).colorScheme.primary;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () {
                                          setState(() {
                                            _myPostsStatusFilter = opt;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? primary.withOpacity(0.1)
                                                : Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: active
                                                    ? primary
                                                    : Colors.grey[300]!,
                                                width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                opt == 'Pending'
                                                    ? Icons.hourglass_empty
                                                    : opt == 'Approved'
                                                        ? Icons.check_circle
                                                        : opt == 'Rejected'
                                                            ? Icons.cancel
                                                            : Icons.list,
                                                size: 16,
                                                color: active
                                                    ? primary
                                                    : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                opt,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: active
                                                      ? primary
                                                      : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
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
                        // Assuming _loadReports() is called elsewhere in the code
                      },
                    ),
                  ],
                  if (postProvider.isLoading ||
                      _isUsernameLoading ||
                      _isLocationLoading)
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
                      // Ensure both 'id' and '_id' are present
                      final postWithId = Map<String, dynamic>.from(post);
                      if (postWithId['_id'] == null &&
                          postWithId['id'] != null) {
                        postWithId['_id'] = postWithId['id'];
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: postWithId),
                              ),
                            );
                            setState(
                                () {}); // Refresh EngagementRow/comment count
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: PostCard(
                              key:
                                  ValueKey(postWithId['_id']?.toString() ?? ''),
                              post: postWithId,
                              username: postWithId['username']?.toString() ??
                                  'Anonymous',
                              whenPosted:
                                  postWithId['whenPosted']?.toString() ??
                                      'Just now',
                              location: postWithId['location']?.toString() ??
                                  'Unknown location',
                              date: postWithId['date']?.toString() ?? '',
                              time: postWithId['time']?.toString() ?? '',
                              reportType:
                                  postWithId['reportType']?.toString() ??
                                      'Unknown',
                              description:
                                  postWithId['description']?.toString() ?? '',
                              numUpvotes:
                                  (postWithId['numUpvotes'] as int?) ?? 0,
                              numDownvotes:
                                  (postWithId['numDownvotes'] as int?) ?? 0,
                              images: (postWithId['images'] as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  [],
                              iconUrl: _userProfilePhotos[postWithId['userId']]
                                          ?.isNotEmpty ==
                                      true
                                  ? _userProfilePhotos[postWithId['userId']]!
                                  : 'assets/icons/person_1.svg',
                              type: 'bordered',
                              onReport: () => _reportPost(postWithId),
                              onDelete: () => _deletePost(postWithId),
                              isOwner: postWithId['userId']?.toString() ==
                                  _prefs.getString('userId'),
                              postId: postWithId['_id']?.toString() ?? '',
                              showDistance: selectedIndex == 3,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          if (_showSuggestions)
            Positioned(
              top: 70,
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
                      final suggestions = _currentPosts
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
                height: MediaQuery.of(context).size.width > 600 ? 50 : 40,
                width: MediaQuery.of(context).size.width > 600 ? 200 : 160,
                child: FloatingActionButton.extended(
                  heroTag: 'prevention_fab',
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
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 16
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/right_arrow.svg',
                          width:
                              MediaQuery.of(context).size.width > 600 ? 24 : 20,
                          height:
                              MediaQuery.of(context).size.width > 600 ? 24 : 20,
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
            bottom: MediaQuery.of(context).size.width > 600 ? 65 : 55,
            right: 3,
            child: Container(
              width: MediaQuery.of(context).size.width > 600 ? 200 : 160,
              height: MediaQuery.of(context).size.width > 600 ? 50 : 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(248, 169, 0, 1),
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'submit_report_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Submit a Report',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? 16
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/icons/add.svg',
                        width:
                            MediaQuery.of(context).size.width > 600 ? 22 : 18,
                        height:
                            MediaQuery.of(context).size.width > 600 ? 22 : 18,
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Unsubscribe from route changes
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    Provider.of<PostProvider>(context, listen: false)
        .fetchPosts(forceRefresh: true);
    _getCurrentLocation(
        showErrors: false); // Don't show errors when returning to screen
    setState(() {});
  }
}
