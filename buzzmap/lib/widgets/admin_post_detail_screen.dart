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
import 'package:buzzmap/errors/flushbar.dart';

class AdminPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  const AdminPostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    final images = (post['images'] is List) ? post['images'] as List : [];
    final validImages =
        images.where((img) => img != null && img.isNotEmpty).toList();
    final title = post['title'] ?? '';
    final content = post['content'] ?? '';
    final publishDate = post['publishDate'] ?? '';
    final category = post['category'] ?? '';
    final references = post['references'] ?? '';
    final postId = post['_id'] ?? '';
    final numUpvotes = post['upvotes']?.length ?? 0;
    final numDownvotes = post['downvotes']?.length ?? 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Announcement',
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            ),
            children: [
              // User info
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Card(
                  color: theme.colorScheme.primary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserInfoRow(
                          type: 'announcement',
                          title:
                              'Quezon City Surveillance and Epidemiology Division',
                          subtitle: _formatDate(publishDate),
                          iconUrl: 'assets/icons/surveillance_logo.svg',
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text.rich(
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
                        const SizedBox(height: 8),
                        // Content
                        Text(
                          content,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (references.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Source: $references',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        // Edge-to-edge image(s)
                        if (validImages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
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
                      ],
                    ),
                  ),
                ),
              ),
              // Engagement row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: EngagementRow(
                  postId: postId,
                  post: post,
                  initialUpvotes: numUpvotes,
                  initialDownvotes: numDownvotes,
                  isAdminPost: true,
                  themeMode: 'light',
                  forceWhiteIcons: false,
                ),
              ),
              // Comments section
              CommentsSection(postId: postId),
              const SizedBox(height: 8),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CommentInputBar(
              postId: postId,
              userName: 'You',
            ),
          ),
        ],
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

  // Add a map to store userId -> profilePhotoUrl
  Map<String, String> _userProfilePhotos = {};

  @override
  void initState() {
    super.initState();
    _initPrefsAndFetch();
    _fetchUserProfiles();
  }

  Future<void> _initPrefsAndFetch() async {
    _prefs = await SharedPreferences.getInstance();
    await _fetchComments();
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

  Future<void> _fetchComments() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    try {
      final token = _prefs.getString('authToken');
      print('Fetching comments for post: ${widget.postId}');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/comments/${widget.postId}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
            'Error loading comments: ${response.statusCode} - ${response.body}');
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
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
              style: TextStyle(color: Colors.white),
            ),
            TextButton(
              onPressed: _fetchComments,
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No comments yet. Be the first to comment!',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(11.0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Comments',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        ...comments.map((comment) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: comment['user']?['_id'] != null &&
                            _userProfilePhotos[comment['user']['_id']]
                                    ?.isNotEmpty ==
                                true
                        ? NetworkImage(
                            _userProfilePhotos[comment['user']['_id']]!)
                        : null,
                    child: (comment['user']?['_id'] == null ||
                            _userProfilePhotos[comment['user']['_id']]
                                    ?.isEmpty !=
                                false)
                        ? Text(
                            (comment['user']?['username'] ?? 'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['user']?['username'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment['content'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w200,
                                    fontSize: 14,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
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

      bool isUpvoted = upvotedComments[commentId] ?? false;
      bool isDownvoted = downvotedComments[commentId] ?? false;

      // If clicking the same vote type, remove the vote
      if ((voteType == 'upvote' && isUpvoted) ||
          (voteType == 'downvote' && isDownvoted)) {
        final response = await http.delete(
          Uri.parse(
              '${Config.baseUrl}/api/v1/adminPosts/comments/$commentId/$voteType'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            upvotedComments[commentId] = false;
            downvotedComments[commentId] = false;
            // Update comment in the list
            final index = comments.indexWhere((c) => c['id'] == commentId);
            if (index != -1) {
              comments[index]['upvotes'] = data['upvotes'] ?? [];
              comments[index]['downvotes'] = data['downvotes'] ?? [];
            }
          });
        }
      } else {
        // Add new vote
        final response = await http.post(
          Uri.parse(
              '${Config.baseUrl}/api/v1/adminPosts/comments/$commentId/$voteType'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            upvotedComments[commentId] = voteType == 'upvote';
            downvotedComments[commentId] = voteType == 'downvote';
            // Update comment in the list
            final index = comments.indexWhere((c) => c['id'] == commentId);
            if (index != -1) {
              comments[index]['upvotes'] = data['upvotes'] ?? [];
              comments[index]['downvotes'] = data['downvotes'] ?? [];
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit vote')),
      );
    }
  }
}

class CommentInputBar extends StatefulWidget {
  final String postId;
  final String userName;

  const CommentInputBar({
    super.key,
    required this.postId,
    required this.userName,
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        await AppFlushBar.showError(
          context,
          title: 'Not Logged In',
          message: 'Please log in to comment',
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
        _focusNode.unfocus();
        // Refresh comments
        if (context.mounted) {
          final commentsSection =
              context.findAncestorStateOfType<_CommentsSectionState>();
          if (commentsSection != null) {
            commentsSection._fetchComments();
          }
        }
        await AppFlushBar.showSuccess(
          context,
          title: 'Comment Posted',
          message: 'Your comment was posted successfully!',
        );
      } else {
        if (context.mounted) {
          await AppFlushBar.showError(
            context,
            title: 'Comment Failed',
            message: 'Failed to post comment',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        await AppFlushBar.showError(
          context,
          title: 'Comment Failed',
          message: 'Failed to post comment',
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
