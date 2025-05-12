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

  @override
  void initState() {
    super.initState();
    upvotes = widget.numUpvotes;
    downvotes = widget.numDownvotes;
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
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
        setState(() {
          upvotes = data['upvotes'].length;
          downvotes = data['downvotes'].length;
          isUpvoted = data['upvotes'].contains(_prefs.getString('userId'));
          isDownvoted = data['downvotes'].contains(_prefs.getString('userId'));
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
        setState(() {
          upvotes = data['upvotes'].length;
          downvotes = data['downvotes'].length;
          isUpvoted = data['upvotes'].contains(_prefs.getString('userId'));
          isDownvoted = data['downvotes'].contains(_prefs.getString('userId'));
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
    final iconColor = widget.themeMode == 'dark'
        ? Colors.white
        : Colors.white; // Changed to white for better contrast

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
              Row(
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
                ],
              ),
            ],
          ),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/share.svg',
                height: 24,
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}
