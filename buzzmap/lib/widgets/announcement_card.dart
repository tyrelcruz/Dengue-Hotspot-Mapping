import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:buzzmap/widgets/admin_post_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzmap/auth/config.dart';

class AnnouncementCard extends StatefulWidget {
  final VoidCallback? onRefresh;

  const AnnouncementCard({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isLoading = true;
  bool _showFullContent = false;
  Map<String, dynamic>? _announcement;
  String _error = '';
  bool _isUpvoted = false;
  bool _isDownvoted = false;
  int _numUpvotes = 0;
  int _numDownvotes = 0;

  // Comments state
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncement();
  }

  Future<void> refresh() async {
    print('🔄 Refreshing announcement card...');
    setState(() {
      _isLoading = true;
      _announcement = null; // Clear the current announcement
    });
    await _fetchAnnouncement();
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  Future<void> _handleVote(String voteType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote')),
        );
        return;
      }

      final announcementId = _announcement!['_id'];
      bool isUpvoted = _isUpvoted;
      bool isDownvoted = _isDownvoted;

      print('🎯 Handling vote:');
      print('Vote type: $voteType');
      print('Announcement ID: $announcementId');
      print('Current upvoted: $isUpvoted');
      print('Current downvoted: $isDownvoted');

      // If clicking the same vote type, remove the vote
      if ((voteType == 'upvote' && isUpvoted) ||
          (voteType == 'downvote' && isDownvoted)) {
        final url =
            '${Config.baseUrl}/api/v1/adminPosts/$announcementId/$voteType';
        print('🗑️ Removing vote: $url');

        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('📡 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _numUpvotes = data['upvotes']?.length ?? 0;
            _numDownvotes = data['downvotes']?.length ?? 0;
            _isUpvoted = false;
            _isDownvoted = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove vote: ${response.body}')),
          );
        }
      } else {
        // Add new vote
        final url =
            '${Config.baseUrl}/api/v1/adminPosts/$announcementId/$voteType';
        print('➕ Adding vote: $url');

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('📡 Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _numUpvotes = data['upvotes']?.length ?? 0;
            _numDownvotes = data['downvotes']?.length ?? 0;
            _isUpvoted = voteType == 'upvote';
            _isDownvoted = voteType == 'downvote';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add vote: ${response.body}')),
          );
        }
      }
    } catch (e) {
      print('❌ Error handling vote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit vote: $e')),
      );
    }
  }

  Future<void> _fetchComments(String announcementId) async {
    setState(() {
      _isLoadingComments = true;
    });
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/comments/$announcementId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _comments = jsonDecode(response.body);
          _isLoadingComments = false;
        });
      } else {
        setState(() {
          _comments = [];
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        _comments = [];
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _fetchAnnouncement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final userId = prefs.getString('userId');

      if (token == null) {
        setState(() {
          _announcement = null;
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/adminposts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final announcements = data.where((post) {
            final category = post['category']?.toString().toLowerCase();
            return category == 'announcement';
          }).toList();

          if (announcements.isNotEmpty) {
            announcements.sort((a, b) {
              try {
                final createdAtA = a['createdAt'] != null
                    ? DateTime.parse(a['createdAt'])
                    : DateTime(1970);
                final createdAtB = b['createdAt'] != null
                    ? DateTime.parse(b['createdAt'])
                    : DateTime(1970);
                final createdAtComparison = createdAtB.compareTo(createdAtA);
                if (createdAtComparison != 0) return createdAtComparison;

                final dateA = a['publishDate'] != null
                    ? DateTime.parse(a['publishDate'])
                    : DateTime(1970);
                final dateB = b['publishDate'] != null
                    ? DateTime.parse(b['publishDate'])
                    : DateTime(1970);
                return dateB.compareTo(dateA);
              } catch (e) {
                return 0;
              }
            });

            final latestAnnouncement = announcements[0];
            setState(() {
              _announcement = {
                '_id': latestAnnouncement['_id'],
                'title': latestAnnouncement['title'],
                'content': latestAnnouncement['content'],
                'publishDate': latestAnnouncement['publishDate'],
                'images': latestAnnouncement['images'] ?? [],
                'references': latestAnnouncement['references'] ??
                    'Quezon City Surveillance and Epidemiology Division',
                'category': latestAnnouncement['category'] ?? 'announcement',
                'upvotes': latestAnnouncement['upvotes'] ?? [],
                'downvotes': latestAnnouncement['downvotes'] ?? [],
              };
              _numUpvotes = latestAnnouncement['upvotes']?.length ?? 0;
              _numDownvotes = latestAnnouncement['downvotes']?.length ?? 0;
              if (userId != null) {
                _isUpvoted =
                    latestAnnouncement['upvotes']?.contains(userId) ?? false;
                _isDownvoted =
                    latestAnnouncement['downvotes']?.contains(userId) ?? false;
              }
              _isLoading = false;
            });
            // Fetch comments for the latest announcement
            if (latestAnnouncement['_id'] != null) {
              await _fetchComments(latestAnnouncement['_id']);
            }
          } else {
            setState(() {
              _announcement = null;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _announcement = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _announcement = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _announcement = null;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      print('❌ Error formatting date: $e');
      return dateString;
    }
  }

  String _formatCategory(String category) {
    // Capitalize first letter and make it more readable
    return category[0].toUpperCase() + category.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcement == null) {
      print('❌ No announcement to display');
      return const SizedBox.shrink(); // Hide the card if no announcement
    }

    final title = _announcement!['title'] as String;
    final content = _announcement!['content'] as String;
    final publishDate = _announcement!['publishDate'] as String;
    final images = _announcement!['images'] as List<dynamic>;
    final references = _announcement!['references'] as String;
    final category = _announcement!['category'] as String;

    print('🎯 Current announcement:');
    print('Title: $title');
    print('Publish date: $publishDate');
    print('Category: $category');
    print('Images: $images');
    print('References: $references');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPostDetailScreen(post: _announcement!),
          ),
        );
      },
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Row
              UserInfoRow(
                title: 'Latest ${_formatCategory(category)}',
                subtitle: 'Quezon City Surveillance and Epidemiology Division',
                iconUrl: 'assets/icons/surveillance_logo.svg',
              ),
              const SizedBox(height: 16),

              // Title with emoji
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '🚨 ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: ' 🚨',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content with show more/less
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: _showFullContent ? null : 3,
                overflow: _showFullContent ? null : TextOverflow.ellipsis,
              ),
              if (content.length > 150) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showFullContent = !_showFullContent;
                    });
                  },
                  child: const Text(
                    'Show More',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],

              // References
              if (references.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Source: $references',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Images
              if (images.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (images.length == 1)
                  // Single image - stretch to full width
                  _buildImage(images[0])
                else
                  // Multiple images - horizontal scroll
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildImage(images[index]),
                        );
                      },
                    ),
                  ),
              ],

              // Date
              const SizedBox(height: 12),
              Text(
                'Published: ${_formatDate(publishDate)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),

              // Engagement Row
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_announcement != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminPostDetailScreen(post: _announcement!),
                      ),
                    );
                  }
                },
                child: EngagementRow(
                  postId: _announcement?['_id'] ?? '',
                  initialUpvotes: _numUpvotes,
                  initialDownvotes: _numDownvotes,
                  isAdminPost: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Fix image URL if needed
    String fixedUrl = imageUrl;
    if (imageUrl.contains('i.ibb.co')) {
      // The URL is already in the correct format from the API
      // No need to modify it
      fixedUrl = imageUrl;
    }

    print('🖼️ Loading image from URL: $fixedUrl');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: fixedUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print('❌ Error loading image: $error');
          print('❌ Failed URL: $url');
          return Container(
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
