import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/vote_provider.dart';
import 'package:buzzmap/providers/comment_provider.dart';
import 'package:buzzmap/providers/user_provider.dart';
import 'package:buzzmap/widgets/post_detail_screen.dart';

class EngagementRow extends StatefulWidget {
  const EngagementRow({
    super.key,
    required this.postId,
    required this.post,
    this.initialUpvotes = 0,
    this.initialDownvotes = 0,
    this.isAdminPost = false,
    this.themeMode = 'dark',
    this.disableCommentButton = false,
  });

  final String postId;
  final Map<String, dynamic> post;
  final int initialUpvotes;
  final int initialDownvotes;
  final bool isAdminPost;
  final String themeMode;
  final bool disableCommentButton;

  @override
  _EngagementRowState createState() => _EngagementRowState();
}

class _EngagementRowState extends State<EngagementRow> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Schedule both operations for the next frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final voteProvider = Provider.of<VoteProvider>(context, listen: false);
        await voteProvider.checkVoteStatus(widget.postId);
        await voteProvider.refreshAllVotes();
      }
    });
  }

  @override
  void didUpdateWidget(EngagementRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      // Schedule the load for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final voteProvider =
              Provider.of<VoteProvider>(context, listen: false);
          await voteProvider.checkVoteStatus(widget.postId);
        }
      });
    }
  }

  Future<void> _handleVote(String voteType) async {
    if (_isLoading) return;

    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Refresh login state before checking
    await userProvider.refreshLoginState();

    if (!userProvider.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to vote')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (voteType == 'upvote') {
        if (voteProvider.isUpvoted(widget.postId)) {
          await voteProvider.removeUpvote(widget.postId,
              isAdminPost: widget.isAdminPost);
        } else {
          await voteProvider.upvotePost(widget.postId,
              isAdminPost: widget.isAdminPost);
        }
      } else if (voteType == 'downvote') {
        if (voteProvider.isDownvoted(widget.postId)) {
          await voteProvider.removeDownvote(widget.postId,
              isAdminPost: widget.isAdminPost);
        } else {
          await voteProvider.downvotePost(widget.postId,
              isAdminPost: widget.isAdminPost);
        }
      }
      // Refresh vote status after voting
      await voteProvider.checkVoteStatus(widget.postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voting: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final commentProvider = Provider.of<CommentProvider>(context);

    // Get vote states - VoteProvider now guarantees non-null values
    final isUpvoted = voteProvider.isUpvoted(widget.postId);
    final isDownvoted = voteProvider.isDownvoted(widget.postId);
    final upvoteCount = voteProvider.getUpvoteCount(widget.postId);
    final downvoteCount = voteProvider.getDownvoteCount(widget.postId);
    final commentCount = commentProvider.getCommentCount(widget.postId) ?? 0;

    print('Building EngagementRow for post ${widget.postId}:');
    print('Upvoted: $isUpvoted');
    print('Downvoted: $isDownvoted');
    print('Upvote count: $upvoteCount');
    print('Downvote count: $downvoteCount');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Upvote Button
              TextButton.icon(
                onPressed: () => _handleVote('upvote'),
                icon: Icon(
                  isUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                  color: isUpvoted ? Colors.green : Colors.grey[600],
                  size: 20,
                ),
                label: Text(
                  formatCount(upvoteCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUpvoted ? Colors.green : Colors.grey[600],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Downvote Button
              TextButton.icon(
                onPressed: () => _handleVote('downvote'),
                icon: Icon(
                  isDownvoted
                      ? Icons.arrow_downward
                      : Icons.arrow_downward_outlined,
                  color: isDownvoted ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
                label: Text(
                  formatCount(downvoteCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDownvoted ? Colors.red : Colors.grey[600],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Comment Button
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(
                        post: widget.post,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                label: Text(
                  formatCount(commentCount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
