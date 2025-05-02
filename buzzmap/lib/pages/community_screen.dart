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

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<List<Map<String, dynamic>>> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/v1/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .where((report) => report['status'] == 'Validated')
          .map<Map<String, dynamic>>((report) {
        return {
          'username': report['user']?['username'] ?? 'Anonymous',
          'whenPosted': 'Just now',
          'location': '${report['barangay']}, Quezon City',
          'barangay': report['barangay'],
          'date': report['date_and_time'].split('T').first,
          'time':
              TimeOfDay.fromDateTime(DateTime.parse(report['date_and_time']))
                  .format(context),
          'reportType': report['report_type'],
          'description': report['description'],
          'images': report['images'] != null
              ? List<String>.from(report['images'])
              : <String>[],
          'iconUrl': 'assets/icons/person_1.svg',
          'status': report['status'],
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch reports');
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await fetchReports();
      setState(() {
        _allPosts = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _currentPosts {
    final query = _searchQuery.toLowerCase();
    final filtered = _allPosts.where((post) {
      return post['username'].toLowerCase().contains(query) ||
          post['description'].toLowerCase().contains(query) ||
          post['reportType'].toLowerCase().contains(query) ||
          post['barangay'].toLowerCase().contains(query);
    }).toList();

    return selectedIndex == 2 ? filtered : filtered;
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
            onRefresh: _loadReports,
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
                    const AnnouncementCard(),
                  ],
                  if (_isLoading)
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
                    ..._currentPosts.map((post) => PostCard(
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
                        )),
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
