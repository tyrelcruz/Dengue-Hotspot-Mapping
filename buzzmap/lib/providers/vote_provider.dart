import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';

class VoteProvider with ChangeNotifier {
  final Map<String, bool> _upvotedPosts = {};
  final Map<String, bool> _downvotedPosts = {};
  final Map<String, int> _upvoteCounts = {};
  final Map<String, int> _downvoteCounts = {};
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  VoteProvider() {
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

  bool isUpvoted(String postId) => _upvotedPosts[postId] ?? false;
  bool isDownvoted(String postId) => _downvotedPosts[postId] ?? false;
  int getUpvoteCount(String postId) => _upvoteCounts[postId] ?? 0;
  int getDownvoteCount(String postId) => _downvoteCounts[postId] ?? 0;

  Future<void> checkVoteStatus(String postId) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) {
          print('Error: No user ID found in SharedPreferences');
          return;
        }

        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        _upvotedPosts[postId] = upvotesList.any((vote) => vote == userId);
        _downvotedPosts[postId] = downvotesList.any((vote) => vote == userId);
        _upvoteCounts[postId] = upvotesList.length;
        _downvoteCounts[postId] = downvotesList.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking vote status: $e');
    }
  }

  Future<void> upvotePost(String postId) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId/upvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        _upvotedPosts[postId] = upvotesList.any((vote) => vote == userId);
        _downvotedPosts[postId] = downvotesList.any((vote) => vote == userId);
        _upvoteCounts[postId] = upvotesList.length;
        _downvoteCounts[postId] = downvotesList.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error upvoting post: $e');
      rethrow;
    }
  }

  Future<void> downvotePost(String postId) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId/downvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        _upvotedPosts[postId] = upvotesList.any((vote) => vote == userId);
        _downvotedPosts[postId] = downvotesList.any((vote) => vote == userId);
        _upvoteCounts[postId] = upvotesList.length;
        _downvoteCounts[postId] = downvotesList.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error downvoting post: $e');
      rethrow;
    }
  }

  Future<void> removeUpvote(String postId) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId/upvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        _upvotedPosts[postId] = upvotesList.any((vote) => vote == userId);
        _downvotedPosts[postId] = downvotesList.any((vote) => vote == userId);
        _upvoteCounts[postId] = upvotesList.length;
        _downvoteCounts[postId] = downvotesList.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error removing upvote: $e');
      rethrow;
    }
  }

  Future<void> removeDownvote(String postId) async {
    if (!_isInitialized) {
      await _initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId/downvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        final upvotesList = List<String>.from(data['upvotes']);
        final downvotesList = List<String>.from(data['downvotes']);

        _upvotedPosts[postId] = upvotesList.any((vote) => vote == userId);
        _downvotedPosts[postId] = downvotesList.any((vote) => vote == userId);
        _upvoteCounts[postId] = upvotesList.length;
        _downvoteCounts[postId] = downvotesList.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error removing downvote: $e');
      rethrow;
    }
  }
}
