import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/comment_provider.dart';
import 'dart:async';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Add a map to store userId -> profilePhotoUrl
  Map<String, String> _userProfilePhotos = {};

  // Carousel state
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _fetchUserProfiles();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      final images =
          (widget.post['images'] is List) ? widget.post['images'] as List : [];
      final validImages =
          images.where((img) => img != null && img.isNotEmpty).toList();
      if (validImages.length <= 1) return;
      setState(() {
        _currentPage = (_currentPage + 1) % validImages.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      await _loadComments();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

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
      } else {
        print('Failed to fetch user profiles: \\${response.body}');
      }
    } catch (e) {
      print('Error fetching user profiles: $e');
    }
  }

  Future<void> _loadComments() async {
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);
    await commentProvider.fetchComments(widget.post['_id']);
  }

  String _getTimeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    // For posts older than 7 days, show month and day
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images =
        (widget.post['images'] is List) ? widget.post['images'] as List : [];
    final validImages =
        images.where((img) => img != null && img.isNotEmpty).toList();
    final username = (widget.post['username'] ?? '').toString();
    final whenPosted = (widget.post['whenPosted'] ?? '').toString();
    final location = (widget.post['location'] ?? '').toString();
    final date = (widget.post['date'] ?? '').toString();
    final time = (widget.post['time'] ?? '').toString();
    final reportType = (widget.post['reportType'] ?? '').toString();
    final description = (widget.post['description'] ?? '').toString();
    final iconUrl =
        _userProfilePhotos[widget.post['userId']]?.isNotEmpty == true
            ? _userProfilePhotos[widget.post['userId']]!
            : 'assets/icons/person_1.svg';
    final numUpvotes = widget.post['numUpvotes'] ?? 0;
    final numDownvotes = widget.post['numDownvotes'] ?? 0;
    final postId = widget.post['_id'] ?? '';

    final commentProvider = Provider.of<CommentProvider>(context);
    final comments = commentProvider.getComments(postId);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          username.isNotEmpty ? username : 'Post',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            ),
            children: [
              // User info
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: UserInfoRow(
                        title: username,
                        subtitle: whenPosted,
                        iconUrl: iconUrl,
                        type: 'post',
                        isOwner: false,
                      ),
                    ),
                    if (widget.post['distance'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistance(widget.post['distance']),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Post details (captions) above the image
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '🕒 Date & Time:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$date, $time',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '⚠️ Report Type:',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reportType,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        Text(
                          '📝 Description',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edge-to-edge image(s)
              if (validImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: validImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: validImages[index],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                      // Left arrow
                      if (validImages.length > 1)
                        Positioned(
                          left: 8,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              int prevPage = _currentPage - 1;
                              if (prevPage < 0)
                                prevPage = validImages.length - 1;
                              _pageController.animateToPage(
                                prevPage,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      // Right arrow
                      if (validImages.length > 1)
                        Positioned(
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              int nextPage =
                                  (_currentPage + 1) % validImages.length;
                              _pageController.animateToPage(
                                nextPage,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      // Dots indicator
                      if (validImages.length > 1)
                        Positioned(
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(validImages.length, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              // Engagement row close to image, in light mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: EngagementRow(
                  postId: postId,
                  post: widget.post,
                  initialUpvotes: numUpvotes,
                  initialDownvotes: numDownvotes,
                  isAdminPost: false,
                  themeMode: 'light',
                  forceWhiteIcons: false,
                ),
              ),
              // Comments section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (comments.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...comments.map((comment) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      comment['user']?['_id'] != null &&
                                              _userProfilePhotos[comment['user']
                                                          ['_id']]
                                                      ?.isNotEmpty ==
                                                  true
                                          ? NetworkImage(_userProfilePhotos[
                                              comment['user']['_id']]!)
                                          : null,
                                  child: (comment['user']?['_id'] == null ||
                                          _userProfilePhotos[comment['user']
                                                      ['_id']]
                                                  ?.isEmpty !=
                                              false)
                                      ? Text(
                                          (comment['user']?['username'] ??
                                                  'U')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment['user']?['username'] ??
                                                'Anonymous',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _getTimeAgo(comment['createdAt']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment['content']),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Remove upvote and downvote buttons
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CommentInputBar(
              postId: postId,
              onCommentPosted: () async {
                await _loadComments();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CommentInputBar extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentPosted;

  const CommentInputBar({
    super.key,
    required this.postId,
    required this.onCommentPosted,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool isPosting = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      isPosting = true;
    });

    try {
      final commentProvider =
          Provider.of<CommentProvider>(context, listen: false);
      await commentProvider.postComment(widget.postId, _controller.text.trim());
      _controller.clear();
      widget.onCommentPosted();
      _focusNode.unfocus();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
          ),
          IconButton(
            icon: isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: isPosting ? null : _postComment,
          ),
        ],
      ),
    );
  }
}
