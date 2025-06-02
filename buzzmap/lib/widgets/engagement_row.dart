import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/vote_provider.dart';
import 'package:buzzmap/widgets/post_detail_screen.dart';

class EngagementRow extends StatefulWidget {
  const EngagementRow({
    super.key,
    required this.numUpvotes,
    required this.numDownvotes,
    required this.postId,
    this.themeMode = 'dark',
    required this.post,
    this.disableCommentButton = false,
  });

  final int numUpvotes;
  final int numDownvotes;
  final String postId;
  final String themeMode;
  final Map<String, dynamic> post;
  final bool disableCommentButton;

  @override
  _EngagementRowState createState() => _EngagementRowState();
}

class _EngagementRowState extends State<EngagementRow> {
  late int _numUpvotes;
  late int _numDownvotes;
  bool _isUpvoted = false;
  bool _isDownvoted = false;
  bool isLoading = false;
  late SharedPreferences _prefs;
  List<Map<String, dynamic>> comments = [];
  bool isLoadingComments = false;
  int commentCount = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _numUpvotes = widget.numUpvotes;
    _numDownvotes = widget.numDownvotes;
    _initializePrefs();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      await _loadVoteStatus();
      await _fetchCommentsCount();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  @override
  void didUpdateWidget(EngagementRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numUpvotes != widget.numUpvotes) {
      _numUpvotes = widget.numUpvotes;
    }
    if (oldWidget.numDownvotes != widget.numDownvotes) {
      _numDownvotes = widget.numDownvotes;
    }
    if (oldWidget.postId != widget.postId && _isInitialized) {
      _loadVoteStatus();
    }
  }

  Future<void> _loadVoteStatus() async {
    final token = _prefs.getString('authToken');
    if (token == null) return;

    try {
      // Determine if this is an admin post or community report
      final isAdminPost = widget.post['isAdminPost'] == true;
      final baseUrl = isAdminPost
          ? '${Config.baseUrl}/api/v1/adminPosts'
          : '${Config.baseUrl}/api/v1/reports';

      print('Loading vote status for post: ${widget.postId}');
      print('Using base URL: $baseUrl');
      print('Is admin post: $isAdminPost');

      // Get the full post data to check vote status
      final response = await http.get(
        Uri.parse('$baseUrl/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Vote status response: ${response.statusCode}');
      print('Vote status body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs.getString('userId');

        if (userId != null && mounted) {
          setState(() {
            // Get the upvotes and downvotes arrays
            final upvotes = List<String>.from(data['upvotes'] ?? []);
            final downvotes = List<String>.from(data['downvotes'] ?? []);

            // Check if the current user has voted
            _isUpvoted = upvotes.contains(userId);
            _isDownvoted = downvotes.contains(userId);

            // Update vote counts
            _numUpvotes = upvotes.length;
            _numDownvotes = downvotes.length;
          });
        }
      }
    } catch (e) {
      print('Error loading vote status: $e');
    }
  }

  Future<void> _handleVote(String voteType) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final token = _prefs.getString('authToken');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote')),
        );
        return;
      }

      // Determine if this is an admin post or community report
      final isAdminPost = widget.post['isAdminPost'] == true;
      final baseUrl = isAdminPost
          ? '${Config.baseUrl}/api/v1/adminPosts'
          : '${Config.baseUrl}/api/v1/reports';

      print('Handling vote: $voteType for post: ${widget.postId}');
      print('Using base URL: $baseUrl');
      print('Is admin post: $isAdminPost');

      // If clicking the same vote type, remove the vote
      if ((voteType == 'upvote' && _isUpvoted) ||
          (voteType == 'downvote' && _isDownvoted)) {
        final response = await http.delete(
          Uri.parse('$baseUrl/${widget.postId}/$voteType'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('Remove vote response: ${response.statusCode}');
        print('Remove vote body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userId = _prefs.getString('userId');

          if (userId != null && mounted) {
            setState(() {
              final upvotes = List<String>.from(data['upvotes'] ?? []);
              final downvotes = List<String>.from(data['downvotes'] ?? []);

              _isUpvoted = upvotes.contains(userId);
              _isDownvoted = downvotes.contains(userId);

              _numUpvotes = upvotes.length;
              _numDownvotes = downvotes.length;
            });
          }
        } else {
          print('Error removing vote: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove vote: ${response.body}')),
          );
        }
      } else {
        // Add new vote
        final response = await http.post(
          Uri.parse('$baseUrl/${widget.postId}/$voteType'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('Add vote response: ${response.statusCode}');
        print('Add vote body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userId = _prefs.getString('userId');

          if (userId != null && mounted) {
            setState(() {
              final upvotes = List<String>.from(data['upvotes'] ?? []);
              final downvotes = List<String>.from(data['downvotes'] ?? []);

              _isUpvoted = upvotes.contains(userId);
              _isDownvoted = downvotes.contains(userId);

              _numUpvotes = upvotes.length;
              _numDownvotes = downvotes.length;
            });
          }
        } else {
          print('Error adding vote: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add vote: ${response.body}')),
          );
        }
      }
    } catch (e) {
      print('Error handling vote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit vote: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchComments() async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (!mounted) return;

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
        if (mounted) {
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
        }
      } else {
        throw Exception('Failed to fetch comments');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load comments'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingComments = false);
      }
    }
  }

  Future<void> _postComment(String content) async {
    if (content.trim().isEmpty) return;
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (!mounted) return;

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
        await _fetchComments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment posted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to post comment');
      }
    } catch (e) {
      print('Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchCommentsCount() async {
    if (!_isInitialized) {
      await _initializePrefs();
    }
    if (!mounted) return;
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
        if (mounted) {
          setState(() {
            commentCount = data.length;
          });
        }
      } else {
        if (mounted) setState(() => commentCount = 0);
      }
    } catch (e) {
      if (mounted) setState(() => commentCount = 0);
    } finally {
      if (mounted) setState(() => isLoadingComments = false);
    }
  }

  String formatCount(int count) {
    return count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = Theme.of(context).extension<CustomColors>();
    final isDark = widget.themeMode == 'dark';
    final iconColor = isDark ? Colors.white : Colors.black;
    final voteProvider = Provider.of<VoteProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: isLoading || !_isInitialized
                    ? null
                    : () => _handleVote('upvote'),
                icon: Icon(
                  _isUpvoted
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_upward_outlined,
                  color: _isUpvoted ? Colors.green : iconColor,
                  size: 22,
                  weight: 100,
                ),
              ),
              isLoadingComments
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Text(
                      formatCount(_numUpvotes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _isUpvoted ? Colors.green : iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: isLoading || !_isInitialized
                    ? null
                    : () => _handleVote('downvote'),
                icon: Icon(
                  _isDownvoted
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_downward_outlined,
                  color: _isDownvoted ? Colors.red : iconColor,
                  size: 22,
                  weight: 100,
                ),
              ),
              isLoadingComments
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Text(
                      formatCount(_numDownvotes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _isDownvoted ? Colors.red : iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: !_isInitialized
                    ? null
                    : widget.disableCommentButton
                        ? null
                        : () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PostDetailScreen(post: widget.post),
                              ),
                            );
                          },
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: iconColor,
                      size: 22,
                      weight: 100,
                    ),
                    const SizedBox(width: 6),
                    isLoadingComments
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(iconColor),
                            ),
                          )
                        : Text(
                            commentCount.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.w500,
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
