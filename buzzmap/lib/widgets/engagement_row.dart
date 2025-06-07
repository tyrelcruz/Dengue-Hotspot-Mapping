import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/user_provider.dart';
import 'package:buzzmap/providers/vote_provider.dart';

class EngagementRow extends StatefulWidget {
  final String postId;
  final int initialUpvotes;
  final int initialDownvotes;
  final bool isAdminPost;

  const EngagementRow({
    super.key,
    required this.postId,
    this.initialUpvotes = 0,
    this.initialDownvotes = 0,
    this.isAdminPost = false,
  });

  @override
  State<EngagementRow> createState() => _EngagementRowState();
}

class _EngagementRowState extends State<EngagementRow> {
  bool _isUpvoted = false;
  bool _isDownvoted = false;
  int _upvotes = 0;
  int _downvotes = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.initialUpvotes;
    _downvotes = widget.initialDownvotes;
    _loadVoteState();
  }

  @override
  void didUpdateWidget(EngagementRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _loadVoteState();
    }
  }

  Future<void> _loadVoteState() async {
    if (!mounted) return;

    final voteProvider = Provider.of<VoteProvider>(context, listen: false);
    await voteProvider.refreshAllVotes();

    setState(() {
      _isUpvoted = voteProvider.isUpvoted(widget.postId);
      _isDownvoted = voteProvider.isDownvoted(widget.postId);
      _upvotes = voteProvider.getUpvoteCount(widget.postId);
      _downvotes = voteProvider.getDownvoteCount(widget.postId);
    });
  }

  Future<void> _handleVote(bool isUpvote) async {
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to vote'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final voteProvider = Provider.of<VoteProvider>(context, listen: false);

      if (isUpvote) {
        if (_isUpvoted) {
          await voteProvider.removeUpvote(widget.postId,
              isAdminPost: widget.isAdminPost);
        } else {
          if (_isDownvoted) {
            await voteProvider.removeDownvote(widget.postId,
                isAdminPost: widget.isAdminPost);
          }
          await voteProvider.upvotePost(widget.postId,
              isAdminPost: widget.isAdminPost);
        }
      } else {
        if (_isDownvoted) {
          await voteProvider.removeDownvote(widget.postId,
              isAdminPost: widget.isAdminPost);
        } else {
          if (_isUpvoted) {
            await voteProvider.removeUpvote(widget.postId,
                isAdminPost: widget.isAdminPost);
          }
          await voteProvider.downvotePost(widget.postId,
              isAdminPost: widget.isAdminPost);
        }
      }

      await _loadVoteState();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : theme.colorScheme.primary;

    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
            color: _isUpvoted ? iconColor : Colors.grey,
          ),
          onPressed: _isLoading ? null : () => _handleVote(true),
        ),
        Text(
          _upvotes.toString(),
          style: TextStyle(
            color: _isUpvoted ? iconColor : Colors.grey,
            fontWeight: _isUpvoted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            _isDownvoted ? Icons.arrow_downward : Icons.arrow_downward_outlined,
            color: _isDownvoted ? iconColor : Colors.grey,
          ),
          onPressed: _isLoading ? null : () => _handleVote(false),
        ),
        Text(
          _downvotes.toString(),
          style: TextStyle(
            color: _isDownvoted ? iconColor : Colors.grey,
            fontWeight: _isDownvoted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
