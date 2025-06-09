import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:buzzmap/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/comment_provider.dart';
import 'package:buzzmap/providers/vote_provider.dart';

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
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
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

  Future<void> _loadComments() async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final postId =
          widget.post['_id']?.toString() ?? widget.post['id']?.toString();
      if (postId == null) {
        throw Exception('Post ID is missing');
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId/comments'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> commentsData = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');
        final currentUserProfilePhoto = _prefs!.getString('profilePhotoUrl');

        setState(() {
          _comments = commentsData
              .map((comment) {
                final user = comment['user'] as Map<String, dynamic>?;
                if (user == null) return null;

                final isCurrentUser = user['_id'] == userId;
                return {
                  ...comment as Map<String, dynamic>,
                  'user': {
                    ...user,
                    'avatarUrl':
                        isCurrentUser && currentUserProfilePhoto != null
                            ? currentUserProfilePhoto
                            : user['avatarUrl'],
                  },
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTimeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
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
    final customColors = Theme.of(context).extension<CustomColors>();
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post Details',
          style: theme.textTheme.titleLarge?.copyWith(
            color: iconColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserInfoRow(
                    title: widget.post['isAnonymous']
                        ? 'Anonymous'
                        : widget.post['username']?.toString() ?? 'Unknown',
                    subtitle:
                        widget.post['whenPosted']?.toString() ?? 'Just now',
                    iconUrl: widget.post['iconUrl']?.toString() ??
                        'assets/icons/person_1.svg',
                    type: 'post',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '📍 Location: ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.post['location']?.toString() ??
                            'Unknown location',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '🕒 Date & Time: ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.post['date']?.toString() ?? ''}, ${widget.post['time']?.toString() ?? ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '⚠️ Report Type: ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.post['reportType']?.toString() ?? 'Unknown',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '📝 Description: ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.post['description']?.toString() ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if ((widget.post['images'] as List<dynamic>?)?.isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 8),
                    _buildImageGrid(
                        (widget.post['images'] as List<dynamic>)
                            .map((e) => e.toString())
                            .toList(),
                        context),
                  ],
                ],
              ),
            ),
            // Engagement row
            Builder(
              builder: (context) {
                final voteProvider =
                    Provider.of<VoteProvider>(context, listen: false);
                final postId = widget.post['_id']?.toString() ??
                    widget.post['id']?.toString() ??
                    '';
                final numUpvotes = voteProvider.getUpvoteCount(postId);
                final numDownvotes = voteProvider.getDownvoteCount(postId);

                return EngagementRow(
                  key: ValueKey('engagement_$postId'),
                  postId: postId,
                  post: widget.post,
                  initialUpvotes: numUpvotes,
                  initialDownvotes: numDownvotes,
                  isAdminPost: false,
                  themeMode: Theme.of(context).brightness == Brightness.dark
                      ? 'dark'
                      : 'light',
                );
              },
            ),
            const SizedBox(height: 16),
            // Comments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_comments.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_comments.isEmpty)
              Center(
                child: Text(
                  'No comments yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ..._comments.map((comment) {
                final user = comment['user'] as Map<String, dynamic>?;
                if (user == null) return const SizedBox.shrink();

                final username = user['username']?.toString() ?? 'Unknown';
                final avatarUrl = user['avatarUrl']?.toString();
                final createdAt = comment['createdAt']?.toString();
                final content = comment['content']?.toString() ?? '';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Text(
                                        username.isNotEmpty
                                            ? username[0].toUpperCase()
                                            : '?',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        content,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 12, top: 4),
                                  child: Text(
                                    createdAt != null
                                        ? _formatTimeAgo(
                                            DateTime.parse(createdAt))
                                        : 'Just now',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
      bottomNavigationBar: CommentInputBar(
        postId: widget.post['_id'],
        onCommentPosted: () async {
          await _loadComments();
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildImageGrid(List<String> images, BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final validImages = images.where((img) => img.isNotEmpty).toList();

    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    int crossAxisCount = 2; // Default grid for 2 images per row
    if (validImages.length == 1) {
      crossAxisCount = 1; // Single image takes full width
    } else if (validImages.length == 2) {
      crossAxisCount = 2; // Two images in one row
    } else if (validImages.length == 3) {
      crossAxisCount = 2; // Two images in the first row, one in the second row
    } else if (validImages.length == 4) {
      crossAxisCount = 2; // Two rows with two images each
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: validImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Open image in full view on click
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: CachedNetworkImage(
                    imageUrl: validImages[index],
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: validImages[index],
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
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

  @override
  void dispose() {
    _controller.dispose();
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
      padding: const EdgeInsets.all(8),
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
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              maxLines: null,
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
