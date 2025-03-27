import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EngagementRow extends StatefulWidget {
  const EngagementRow({
    super.key,
    required this.numUpvotes,
    required this.numDownvotes,
    required this.numComments,
    required this.numShares,
    this.themeMode = 'dark',
  });

  final int numUpvotes;
  final int numDownvotes;
  final int numComments;
  final int numShares;
  final String themeMode;

  @override
  _EngagementRowState createState() => _EngagementRowState();
}

class _EngagementRowState extends State<EngagementRow> {
  int upvotes = 0;
  int downvotes = 0;
  bool isUpvoted = false;
  bool isDownvoted = false;

  @override
  void initState() {
    super.initState();
    upvotes = widget.numUpvotes;
    downvotes = widget.numDownvotes;
  }

  void toggleUpvote() {
    setState(() {
      if (isUpvoted) {
        upvotes--;
      } else {
        upvotes++;
        if (isDownvoted) {
          downvotes--;
          isDownvoted = false;
        }
      }
      isUpvoted = !isUpvoted;
    });
  }

  void toggleDownvote() {
    setState(() {
      if (isDownvoted) {
        downvotes--;
      } else {
        downvotes++;
        if (isUpvoted) {
          upvotes--;
          isUpvoted = false;
        }
      }
      isDownvoted = !isDownvoted;
    });
  }

  String formatCount(int count) {
    return count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        widget.themeMode == 'dark' ? Colors.white : theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: toggleUpvote,
                  icon: Icon(
                    Icons.arrow_upward,
                    color: isUpvoted ? Colors.green : iconColor,
                  ),
                ),
                Text(
                  formatCount(upvotes),
                  style: theme.textTheme.bodyMedium?.copyWith(color: iconColor),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: toggleDownvote,
                  icon: Icon(
                    Icons.arrow_downward,
                    color: isDownvoted ? Colors.red : iconColor,
                  ),
                ),
                Text(
                  formatCount(downvotes),
                  style: theme.textTheme.bodyMedium?.copyWith(color: iconColor),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/comment.svg',
                  height: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                Text(
                  formatCount(widget.numComments),
                  style: theme.textTheme.bodyMedium?.copyWith(color: iconColor),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/share.svg',
              height: 20,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              formatCount(widget.numShares),
              style: theme.textTheme.bodyMedium?.copyWith(color: iconColor),
            ),
          ],
        ),
      ],
    );
  }
}
