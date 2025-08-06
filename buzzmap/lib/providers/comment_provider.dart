import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';

class CommentProvider with ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> _comments = {};
  final Map<String, int> _commentCounts = {};
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  CommentProvider() {
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  List<Map<String, dynamic>> getComments(String postId) =>
      _comments[postId] ?? [];
  int getCommentCount(String postId) => _commentCounts[postId] ?? 0;

  Future<void> fetchComments(String postId, {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/$endpoint/$postId/comments'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _comments[postId] = data.map((comment) {
          final user = comment['user'] ?? {};
          final currentUserId = _prefs!.getString('userId');
          final currentUserProfilePhotoUrl =
              _prefs!.getString('profilePhotoUrl');

          // Use the current user's profile photo if the comment is from the current user
          final avatarUrl = (user['_id'] == currentUserId &&
                  currentUserProfilePhotoUrl != null &&
                  currentUserProfilePhotoUrl.isNotEmpty)
              ? currentUserProfilePhotoUrl
              : user['profilePhotoUrl'];

          return {
            'id': comment['_id'],
            'content': comment['content'],
            'user': {
              ...user,
              'avatarUrl': avatarUrl,
            },
            'createdAt': comment['createdAt'],
            'upvotes': comment['upvotes'] ?? [],
            'downvotes': comment['downvotes'] ?? [],
          };
        }).toList();
        _commentCounts[postId] = data.length;
        print(
            'CommentProvider: Updated comment count for $postId to ${data.length}');
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> postComment(String postId, String content,
      {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/$endpoint/$postId/comments'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        // Fetch updated comments after posting
        await fetchComments(postId, isAdminPost: isAdminPost);
      } else {
        throw Exception('Failed to post comment');
      }
    } catch (e) {
      print('Error posting comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId,
      {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      final response = await http.delete(
        Uri.parse(
            '${Config.baseUrl}/api/v1/$endpoint/$postId/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Fetch updated comments after deletion
        await fetchComments(postId, isAdminPost: isAdminPost);
      } else {
        throw Exception('Failed to delete comment');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }
}
