import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostProvider with ChangeNotifier {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<Map<String, dynamic>> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get shouldRefresh =>
      _lastFetchTime == null ||
      DateTime.now().difference(_lastFetchTime!) > _cacheDuration;

  String _formatWhenPosted(String dateTimeStr) {
    final DateTime postDate = DateTime.parse(dateTimeStr);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(postDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> fetchPosts({bool forceRefresh = false}) async {
    if (!forceRefresh && !shouldRefresh && _posts.isNotEmpty) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final currentUserId = prefs.getString('userId');
      final currentUserProfilePhotoUrl = prefs.getString('profilePhotoUrl');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${Config.postsUrl}?status=Validated'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _posts = data.map((post) {
          final DateTime reportDate = DateTime.parse(post['date_and_time']);
          final DateTime now = DateTime.now();
          final Duration difference = now.difference(reportDate);

          String whenPosted;
          if (difference.inDays > 0) {
            whenPosted = '${difference.inDays} days ago';
          } else if (difference.inHours > 0) {
            whenPosted = '${difference.inHours} hours ago';
          } else if (difference.inMinutes > 0) {
            whenPosted = '${difference.inMinutes} minutes ago';
          } else {
            whenPosted = 'Just now';
          }

          final username = post['user']?['username'] ?? 'Anonymous';
          final email = post['user']?['email'] ?? '';
          final userId = post['user']?['_id'] ?? '';

          // Get vote counts from the backend response
          final upvotes = post['upvotes'] ?? [];
          final downvotes = post['downvotes'] ?? [];

          return {
            'id': post['_id'],
            'username': username,
            'email': email,
            'userId': userId,
            'whenPosted': whenPosted,
            'location': '${post['barangay']}, Quezon City',
            'barangay': post['barangay'],
            'date': '${reportDate.month}/${reportDate.day}/${reportDate.year}',
            'time':
                '${reportDate.hour.toString().padLeft(2, '0')}:${reportDate.minute.toString().padLeft(2, '0')}',
            'reportType': post['report_type'],
            'description': post['description'],
            'images': post['images'] != null
                ? List<String>.from(post['images'])
                : <String>[],
            'iconUrl': (userId == currentUserId &&
                    currentUserProfilePhotoUrl != null &&
                    currentUserProfilePhotoUrl.isNotEmpty)
                ? currentUserProfilePhotoUrl
                : 'assets/icons/person_1.svg',
            'status': post['status'],
            'numUpvotes': upvotes.length,
            'numDownvotes': downvotes.length,
            'upvotes': upvotes,
            'downvotes': downvotes,
            'date_and_time': post['date_and_time'],
            'specific_location': post['specific_location'],
            'isAnonymous': post['isAnonymous'] ?? false,
            'anonymousId': post['anonymousId'],
            '_commentCount': post['_commentCount'] ?? 0,
            '_latestComment': post['_latestComment'],
          };
        }).toList();
        _lastFetchTime = DateTime.now();
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPost(Map<String, dynamic> post) async {
    _posts.insert(0, post);
    notifyListeners();
  }

  Future<void> updatePost(
      String postId, Map<String, dynamic> updatedPost) async {
    final index = _posts.indexWhere((post) => post['_id'] == postId);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((post) => post['_id'] == postId);
    notifyListeners();
  }

  void clearCache() {
    _posts = [];
    _lastFetchTime = null;
    notifyListeners();
  }
}
