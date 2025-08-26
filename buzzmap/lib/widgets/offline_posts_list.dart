import 'package:flutter/material.dart';
import 'package:buzzmap/services/offline_post_service.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';

class OfflinePostsList extends StatefulWidget {
  const OfflinePostsList({super.key});

  @override
  State<OfflinePostsList> createState() => _OfflinePostsListState();
}

class _OfflinePostsListState extends State<OfflinePostsList> {
  final OfflinePostService _offlineService = OfflinePostService();
  List<Map<String, dynamic>> _offlinePosts = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Define offline-specific colors
  final Color _offlineColor = const Color(0xFF6B7280); // Slate gray
  final Color _offlineBgColor =
      const Color(0xFFF3F4F6); // Light gray background

  @override
  void initState() {
    super.initState();
    _loadOfflinePosts();
    _offlineService.offlinePostsStream.listen((_) {
      _loadOfflinePosts();
    });
  }

  Future<void> _loadOfflinePosts() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final posts = await _offlineService.getOfflinePosts();
      if (mounted) {
        setState(() {
          _offlinePosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading offline posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _offlinePosts = [];
        });
      }
    }
  }

  Widget _buildCarouselItem(Map<String, dynamic> post, int index) {
    final timestamp = DateTime.parse(post['date_and_time']);
    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(timestamp);

    // New colors for highlight
    final Color highlightColor = const Color(0xFFFFA726); // Light orange
    final Color badgeBgColor = const Color(0xFFFFF3E0); // Very light orange
    final Color badgeTextColor = const Color(0xFFFB8C00); // Orange

    // Add back image path logic for thumbnail
    String? imagePath;
    if (post['images'] != null &&
        post['images'] is List &&
        post['images'].isNotEmpty) {
      final List images = post['images'];
      if (images.isNotEmpty &&
          images[0] != null &&
          images[0].toString().isNotEmpty) {
        imagePath = images[0].toString();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 3, // Slightly higher elevation
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlightColor.withOpacity(0.7), // Orange border
          width: 2,
        ),
      ),
      shadowColor: highlightColor.withOpacity(0.2),
      child: InkWell(
        onTap: () {
          // Handle tap if needed
        },
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    // Main card content in a Padding (small padding only)
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: highlightColor
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.cloud_off,
                                            color:
                                                highlightColor, // Orange icon
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post['report_type'] ??
                                                    'Offline Report',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: highlightColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                post['barangay'] ??
                                                    'Unknown Location',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBgColor,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: highlightColor
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            'Pending Sync',
                                            style: TextStyle(
                                              color: badgeTextColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.grey[500],
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            await _offlineService
                                                .removeOfflinePost(index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post['description'] ?? 'No description provided',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_offlinePosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          'No pending offline posts',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            enableInfiniteScroll: _offlinePosts.length > 1,
            autoPlay: _offlinePosts.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: _offlinePosts.asMap().entries.map((entry) {
            return _buildCarouselItem(entry.value, entry.key);
          }).toList(),
        ),
        if (_offlinePosts.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _offlinePosts.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _offlineColor.withOpacity(
                    _currentIndex == entry.key ? 0.9 : 0.4,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
