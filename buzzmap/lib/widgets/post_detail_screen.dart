import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:buzzmap/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostDetailScreen({super.key, required this.post});

  Future<String> _getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'You';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = (post['images'] is List) ? post['images'] as List : [];
    final validImages =
        images.where((img) => img != null && img.isNotEmpty).toList();
    final username = (post['username'] ?? '').toString();
    final whenPosted = (post['whenPosted'] ?? '').toString();
    final location = (post['location'] ?? '').toString();
    final date = (post['date'] ?? '').toString();
    final time = (post['time'] ?? '').toString();
    final reportType = (post['reportType'] ?? '').toString();
    final description = (post['description'] ?? '').toString();
    final iconUrl = (post['iconUrl'] ?? 'assets/icons/person_1.svg').toString();
    final numUpvotes = post['numUpvotes'] ?? 0;
    final numDownvotes = post['numDownvotes'] ?? 0;
    final postId = post['id'] ?? '';

    return FutureBuilder<String>(
      future: _getCurrentUsername(),
      builder: (context, snapshot) {
        final currentUserName = snapshot.data ?? 'You';
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
          body: ListView(
            padding: EdgeInsets.zero,
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
                    if (post['distance'] != null)
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
                              _formatDistance(post['distance']),
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
                SizedBox(
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
              // Engagement row close to image, in light mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: EngagementRow(
                  numUpvotes: numUpvotes,
                  numDownvotes: numDownvotes,
                  postId: postId,
                  themeMode: 'light',
                  post: post,
                  disableCommentButton: true,
                ),
              ),
              // Comments section (inline, not Expanded)
              CommentsSection(postId: postId),
            ],
          ),
          bottomNavigationBar:
              CommentInputBar(postId: postId, userName: currentUserName),
        );
      },
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }
}

class CommentsSection extends StatefulWidget {
  final String postId;
  const CommentsSection({super.key, required this.postId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  bool isError = false;
  late SharedPreferences _prefs;
  Map<String, bool> upvotedComments = {};
  Map<String, bool> downvotedComments = {};

  @override
  void initState() {
    super.initState();
    _initPrefsAndFetch();
  }

  Future<void> _initPrefsAndFetch() async {
    _prefs = await SharedPreferences.getInstance();
    await _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    try {
      final token = _prefs.getString('authToken');
      print('Fetching comments for post: ${widget.postId}'); // Debug log

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}/comments'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          comments = data
              .map((comment) => {
                    'id': comment['_id'],
                    'content': comment['content'],
                    'user': comment['user'],
                    'createdAt': comment['createdAt'],
                    'upvotes': comment['upvotes'] ?? [],
                    'downvotes': comment['downvotes'] ?? [],
                  })
              .toList();

          // Initialize vote states
          for (var comment in comments) {
            final userId = _prefs.getString('userId');
            if (userId != null) {
              upvotedComments[comment['id']] =
                  (comment['upvotes'] as List).contains(userId);
              downvotedComments[comment['id']] =
                  (comment['downvotes'] as List).contains(userId);
            }
          }

          isLoading = false;
        });
      } else {
        print(
            'Error loading comments: ${response.statusCode} - ${response.body}'); // Debug log
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Exception loading comments: $e'); // Debug log
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _handleVote(String commentId, String voteType) async {
    try {
      final token = _prefs.getString('authToken');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote')),
        );
        return;
      }

      // Check if already voted
      bool isUpvoted = upvotedComments[commentId] == true;
      bool isDownvoted = downvotedComments[commentId] == true;

      // If clicking the same vote type, remove the vote
      if ((voteType == 'upvote' && isUpvoted) ||
          (voteType == 'downvote' && isDownvoted)) {
        final response = await http.delete(
          Uri.parse('${Config.baseUrl}/api/v1/comments/$commentId/$voteType'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            final commentIndex =
                comments.indexWhere((c) => c['id'] == commentId);
            if (commentIndex != -1) {
              comments[commentIndex]['upvotes'] = data['upvotes'] ?? [];
              comments[commentIndex]['downvotes'] = data['downvotes'] ?? [];
              upvotedComments[commentId] = false;
              downvotedComments[commentId] = false;
            }
          });
        } else {
          print(
              'Error removing vote: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove vote')),
          );
        }
      } else {
        // Add new vote
        final response = await http.post(
          Uri.parse('${Config.baseUrl}/api/v1/comments/$commentId/$voteType'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            final commentIndex =
                comments.indexWhere((c) => c['id'] == commentId);
            if (commentIndex != -1) {
              comments[commentIndex]['upvotes'] = data['upvotes'] ?? [];
              comments[commentIndex]['downvotes'] = data['downvotes'] ?? [];
              upvotedComments[commentId] = voteType == 'upvote';
              downvotedComments[commentId] = voteType == 'downvote';
            }
          });
        } else {
          print('Error adding vote: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit vote')),
          );
        }
      }
    } catch (e) {
      print('Exception during vote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit vote')),
      );
    }
  }

  void refreshComments() => _fetchComments();

  String _getTimeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Failed to load comments',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (comments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No comments yet. Be the first to comment!',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(11.0),
        ),
        ...comments.map((comment) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: comment['user']?['avatarUrl'] != null
                        ? NetworkImage(comment['user']['avatarUrl'])
                        : null,
                    child: comment['user']?['avatarUrl'] == null
                        ? Text(
                            (comment['user']?['username'] ?? 'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  // Comment bubble and actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bubble
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['user']?['username'] ?? 'Unknown',
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
                        // Actions row
                        Row(
                          children: [
                            Text(
                              _getTimeAgo(comment['createdAt']),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            // Upvote button
                            GestureDetector(
                              onTap: () => _handleVote(comment['id'], 'upvote'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: upvotedComments[comment['id']] == true
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      upvotedComments[comment['id']] == true
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_upward_outlined,
                                      size: 16,
                                      color:
                                          upvotedComments[comment['id']] == true
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[600],
                                      weight: 100,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(comment['upvotes'] as List).length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: upvotedComments[comment['id']] ==
                                                true
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Downvote button
                            GestureDetector(
                              onTap: () =>
                                  _handleVote(comment['id'], 'downvote'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      downvotedComments[comment['id']] == true
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      downvotedComments[comment['id']] == true
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_downward_outlined,
                                      size: 16,
                                      color: downvotedComments[comment['id']] ==
                                              true
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                      weight: 100,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(comment['downvotes'] as List).length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            downvotedComments[comment['id']] ==
                                                    true
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class CommentInputBar extends StatefulWidget {
  final String postId;
  final String userName;
  const CommentInputBar(
      {super.key, required this.postId, required this.userName});

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool isPosting = false;

  Future<void> _postComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => isPosting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}/comments'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 201) {
        _controller.clear();
        // Refresh comments in CommentsSection
        final commentsSectionState =
            context.findAncestorStateOfType<_CommentsSectionState>();
        commentsSectionState?.refreshComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Comment posted successfully'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to post comment'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to post comment'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.gif_box_outlined),
                  onPressed: () {}, // Add GIF picker logic
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {}, // Add emoji picker logic
                ),
                IconButton(
                  icon: const Icon(Icons.face_4_outlined),
                  onPressed: () {}, // Add sticker logic
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  onPressed: () {}, // Add effects logic
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !isPosting,
                    decoration: InputDecoration(
                      hintText: 'Comment as ${widget.userName}',
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: isPosting ? null : _postComment,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
