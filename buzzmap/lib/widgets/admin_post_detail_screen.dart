import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:buzzmap/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/comment_provider.dart';

class AdminPostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const AdminPostDetailScreen({super.key, required this.post});

  @override
  State<AdminPostDetailScreen> createState() => _AdminPostDetailScreenState();
}

class _AdminPostDetailScreenState extends State<AdminPostDetailScreen> {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

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
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    final images =
        (widget.post['images'] is List) ? widget.post['images'] as List : [];
    final validImages =
        images.where((img) => img != null && img.isNotEmpty).toList();
    final title = widget.post['title'] ?? '';
    final content = widget.post['content'] ?? '';
    final publishDate = widget.post['publishDate'] ?? '';
    final category = widget.post['category'] ?? '';
    final references = widget.post['references'] ?? '';
    final postId = widget.post['_id'] ?? '';
    final numUpvotes = widget.post['upvotes']?.length ?? 0;
    final numDownvotes = widget.post['downvotes']?.length ?? 0;

    final commentProvider = Provider.of<CommentProvider>(context);
    final comments = commentProvider.getComments(postId);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          'Announcement',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: theme.colorScheme.primary,
      body: Container(
        color: theme.colorScheme.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // User info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: UserInfoRow(
                type: 'announcement',
                title: 'Quezon City Surveillance and Epidemiology Division',
                subtitle: _formatDate(publishDate),
                iconUrl: 'assets/icons/surveillance_logo.svg',
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '🚨 ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: ' 🚨',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            // References
            if (references.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Source: $references',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ),
            // Edge-to-edge image(s)
            if (validImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: PageView.builder(
                    itemCount: validImages.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: validImages[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            // Engagement row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: EngagementRow(
                postId: postId,
                post: widget.post,
                initialUpvotes: numUpvotes,
                initialDownvotes: numDownvotes,
                isAdminPost: true,
                themeMode: 'dark',
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
                  const SizedBox(height: 16),
                  if (comments.isEmpty)
                    Center(
                      child: Text(
                        'No comments yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
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
                                backgroundImage: comment['user']
                                            ?['avatarUrl'] !=
                                        null
                                    ? NetworkImage(comment['user']['avatarUrl'])
                                    : null,
                                child: comment['user']?['avatarUrl'] == null
                                    ? Text(
                                        (comment['user']?['username'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment['user']?['username'] ??
                                                'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            comment['content'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w200,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getTimeAgo(comment['createdAt'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: CommentInputBar(
        postId: postId,
        onCommentPosted: _loadComments,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

class CommentInputBar extends StatefulWidget {
  final String postId;
  final Function() onCommentPosted;

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to comment')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/comments/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': _controller.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _controller.clear();
        // Refresh comments
        if (context.mounted) {
          widget.onCommentPosted();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to post comment')),
          );
        }
      }
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
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white30,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.gif_box_outlined, color: Colors.white70),
                  onPressed: () {}, // Add GIF picker logic
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined,
                      color: Colors.white70),
                  onPressed: () {}, // Add emoji picker logic
                ),
                IconButton(
                  icon:
                      const Icon(Icons.face_4_outlined, color: Colors.white70),
                  onPressed: () {}, // Add sticker logic
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome_outlined,
                      color: Colors.white70),
                  onPressed: () {}, // Add effects logic
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !isPosting,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Comment as You',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: isPosting ? null : _postComment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
