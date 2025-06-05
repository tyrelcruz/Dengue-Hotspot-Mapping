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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Schedule both opeRrations for the next frame to avoid setState during build
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

  Future<void> _handleVote(bool isUpvote) async {
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
      if (isUpvote) {
        if (voteProvider.isUpvoted(widget.postId)) {
          await voteProvider.removeUpvote(widget.postId);
        } else {
          await voteProvider.upvotePost(widget.postId);
        }
      } else {
        if (voteProvider.isDownvoted(widget.postId)) {
          await voteProvider.removeDownvote(widget.postId);
        } else {
          await voteProvider.downvotePost(widget.postId);
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

    // Get vote states
    final isUpvoted = voteProvider.isUpvoted(widget.postId);
    final isDownvoted = voteProvider.isDownvoted(widget.postId);
    final upvoteCount = voteProvider.getUpvoteCount(widget.postId);
    final downvoteCount = voteProvider.getDownvoteCount(widget.postId);
    final commentCount = commentProvider.getCommentCount(widget.postId);

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
              IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: isUpvoted ? Colors.blue : Colors.grey,
                ),
                onPressed: _isLoading ? null : () => _handleVote(true),
              ),
              Text(
                formatCount(upvoteCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUpvoted ? Colors.blue : iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  Icons.arrow_downward,
                  color: isDownvoted ? Colors.red : Colors.grey,
                ),
                onPressed: _isLoading ? null : () => _handleVote(false),
              ),
              Text(
                formatCount(downvoteCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDownvoted ? Colors.red : iconColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 15),
              if (!widget.disableCommentButton)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          post: widget.post,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        color: iconColor,
                        size: 22,
                        weight: 100,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatCount(commentCount),
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
