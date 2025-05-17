import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EngagementRow extends StatefulWidget {
  const EngagementRow({
    super.key,
    required this.numUpvotes,
    required this.numDownvotes,
    required this.postId,
    this.themeMode = 'dark',
  });

  final int numUpvotes;
  final int numDownvotes;
  final String postId;
  final String themeMode;

  @override
  _EngagementRowState createState() => _EngagementRowState();
}

class _EngagementRowState extends State<EngagementRow> {
  int upvotes = 0;
  int downvotes = 0;
  bool isUpvoted = false;
  bool isDownvoted = false;
  bool isLoading = false;
  late SharedPreferences _prefs;
  List<Map<String, dynamic>> comments = [];
  bool isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    upvotes = widget.numUpvotes;
    downvotes = widget.numDownvotes;
    _initializePrefs();
    _checkVoteStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _checkVoteStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs.getString('userId');

        // Handle the arrays directly since they're already populated with _id
        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        setState(() {
          upvotes = upvotesList.length;
          downvotes = downvotesList.length;
          isUpvoted = upvotesList.contains(userId);
          isDownvoted = downvotesList.contains(userId);
        });
      }
    } catch (e) {
      print('Error checking vote status: $e');
    }
  }

  Future<void> _fetchComments() async {
    setState(() => isLoadingComments = true);
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}/comments'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          comments = data
              .map((comment) => {
                    'id': comment['_id'],
                    'content': comment['content'],
                    'user': comment['user'],
                    'createdAt': comment['createdAt'],
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to fetch comments');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load comments'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoadingComments = false);
    }
  }

  Future<void> _postComment(String content) async {
    if (content.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}/comments'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        await _fetchComments(); // Refresh comments
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to post comment');
      }
    } catch (e) {
      print('Error posting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _upvotePost() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}/upvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs.getString('userId');

        // Handle the arrays directly since they're already populated with _id
        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        setState(() {
          upvotes = upvotesList.length;
          downvotes = downvotesList.length;
          isUpvoted = upvotesList.contains(userId);
          isDownvoted = downvotesList.contains(userId);
        });
      } else {
        throw Exception('Failed to upvote post');
      }
    } catch (e) {
      print('Error upvoting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upvote post'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _downvotePost() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/${widget.postId}/downvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs.getString('userId');

        // Handle the arrays directly since they're already populated with _id
        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        setState(() {
          upvotes = upvotesList.length;
          downvotes = downvotesList.length;
          isUpvoted = upvotesList.contains(userId);
          isDownvoted = downvotesList.contains(userId);
        });
      } else {
        throw Exception('Failed to downvote post');
      }
    } catch (e) {
      print('Error downvoting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to downvote post'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String formatCount(int count) {
    return count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = Theme.of(context).extension<CustomColors>();
    final iconColor = widget.themeMode == 'dark' ? Colors.white : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: isLoading ? null : _upvotePost,
                    icon: Icon(
                      Icons.arrow_upward,
                      color: isUpvoted ? Colors.green : iconColor,
                      size: 24,
                    ),
                  ),
                  Text(
                    formatCount(upvotes),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: isLoading ? null : _downvotePost,
                    icon: Icon(
                      Icons.arrow_downward,
                      color: isDownvoted ? Colors.red : iconColor,
                      size: 24,
                    ),
                  ),
                  Text(
                    formatCount(downvotes),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () async {
                  await _fetchComments(); // Fetch comments before showing dialog
                  if (!mounted) return;

                  showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Comments'),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                await _fetchComments();
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoadingComments)
                                const Center(child: CircularProgressIndicator())
                              else if (comments.isEmpty)
                                const Center(
                                  child: Text(
                                      'No comments yet. Be the first to comment!'),
                                )
                              else
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: comments.length,
                                    itemBuilder: (context, index) {
                                      final comment = comments[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    child: Text(
                                                      comment['user']
                                                              ['username'][0]
                                                          .toUpperCase(),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    comment['user']['username'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(comment['content']),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateTime.parse(
                                                        comment['createdAt'])
                                                    .toLocal()
                                                    .toString()
                                                    .split('.')[0],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Write a comment...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  await _postComment(_commentController.text);
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Post Comment'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/comment.svg',
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Comment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
