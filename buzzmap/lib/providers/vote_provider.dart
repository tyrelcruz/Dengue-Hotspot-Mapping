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
  bool _isLoading = false;
  bool _isLoadingAllVotes = false;

  VoteProvider() {
    initializePrefs();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingAllVotes => _isLoadingAllVotes;

  Future<void> initializePrefs() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      await _loadPersistedVoteStates();
      notifyListeners();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  Future<void> _loadPersistedVoteStates() async {
    if (_prefs == null) return;

    try {
      _isLoadingAllVotes = true;

      final userId = _prefs!.getString('userId');
      if (userId == null) return;

      // Get all posts that have votes
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        final List<dynamic> posts = responseData is Map<String, dynamic>
            ? responseData['reports'] ?? []
            : responseData is List
                ? responseData
                : [];

        for (var post in posts) {
          if (post is! Map<String, dynamic>) continue;

          final postId = post['_id']?.toString();
          if (postId == null) continue;

          final upvotesList = List<String>.from(post['upvotes'] ?? []);
          final downvotesList = List<String>.from(post['downvotes'] ?? []);

          _updateVoteState(postId, upvotesList, downvotesList, userId);
        }

        // Also load admin posts votes
        final adminResponse = await http.get(
          Uri.parse('${Config.baseUrl}/api/v1/adminPosts'),
          headers: {
            'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
            'Content-Type': 'application/json',
          },
        );

        if (adminResponse.statusCode == 200) {
          final dynamic adminData = jsonDecode(adminResponse.body);
          final List<dynamic> adminPosts = adminData is Map<String, dynamic>
              ? adminData['adminPosts'] ?? []
              : adminData is List
                  ? adminData
                  : [];

          for (var post in adminPosts) {
            if (post is! Map<String, dynamic>) continue;

            final postId = post['_id']?.toString();
            if (postId == null) continue;

            final upvotesList = List<String>.from(post['upvotes'] ?? []);
            final downvotesList = List<String>.from(post['downvotes'] ?? []);

            _updateVoteState(postId, upvotesList, downvotesList, userId);
          }
        }
      }
    } catch (e) {
      // Silent error handling
    } finally {
      _isLoadingAllVotes = false;
      notifyListeners();
    }
  }

  void _updateVoteState(String postId, List<String> upvotesList,
      List<String> downvotesList, String userId) {
    _upvotedPosts[postId] = upvotesList.contains(userId);
    _downvotedPosts[postId] = downvotesList.contains(userId);
    _upvoteCounts[postId] = upvotesList.length;
    _downvoteCounts[postId] = downvotesList.length;

    // Store vote state in SharedPreferences
    _prefs?.setBool('upvoted_$postId', _upvotedPosts[postId] ?? false);
    _prefs?.setBool('downvoted_$postId', _downvotedPosts[postId] ?? false);
    _prefs?.setInt('upvotes_$postId', _upvoteCounts[postId] ?? 0);
    _prefs?.setInt('downvotes_$postId', _downvoteCounts[postId] ?? 0);
  }

  Future<void> refreshAllVotes() async {
    if (!_isInitialized) {
      await initializePrefs();
    }
    await _loadPersistedVoteStates();
    notifyListeners();
  }

  Future<void> checkVoteStatus(String postId) async {
    if (!_isInitialized) {
      await initializePrefs();
    }

    if (_prefs == null) {
      return;
    }

    // If we already have the vote state in memory, don't fetch it again
    if (_upvotedPosts.containsKey(postId) &&
        _downvotedPosts.containsKey(postId)) {
      return;
    }

    try {
      _isLoading = true;

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports/$postId'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) {
          return;
        }

        final upvotesList = List<String>.from(data['upvotes'] ?? []);
        final downvotesList = List<String>.from(data['downvotes'] ?? []);

        _updateVoteState(postId, upvotesList, downvotesList, userId);
        notifyListeners();
      }
    } catch (e) {
      // Silent error handling
    } finally {
      _isLoading = false;
    }
  }

  Future<void> upvotePost(String postId, {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await initializePrefs();
    }

    if (_prefs == null) {
      return;
    }

    try {
      _isLoading = true;

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/$endpoint/$postId/upvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        // Update vote counts from response
        _upvoteCounts[postId] = data['upvotes'] ?? 0;
        _downvoteCounts[postId] = data['downvotes'] ?? 0;

        // Update vote state
        _upvotedPosts[postId] = true;
        _downvotedPosts[postId] = false;

        // Store in SharedPreferences
        _prefs?.setInt('upvotes_$postId', _upvoteCounts[postId] ?? 0);
        _prefs?.setInt('downvotes_$postId', _downvoteCounts[postId] ?? 0);
        _prefs?.setBool('upvoted_$postId', true);
        _prefs?.setBool('downvoted_$postId', false);

        notifyListeners();
      } else {
        throw Exception('Failed to upvote post: ${response.body}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> downvotePost(String postId, {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await initializePrefs();
    }

    if (_prefs == null) {
      return;
    }

    try {
      _isLoading = true;

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/$endpoint/$postId/downvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        // Update vote counts from response
        _upvoteCounts[postId] = data['upvotes'] ?? 0;
        _downvoteCounts[postId] = data['downvotes'] ?? 0;

        // Update vote state
        _upvotedPosts[postId] = false;
        _downvotedPosts[postId] = true;

        // Store in SharedPreferences
        _prefs?.setInt('upvotes_$postId', _upvoteCounts[postId] ?? 0);
        _prefs?.setInt('downvotes_$postId', _downvoteCounts[postId] ?? 0);
        _prefs?.setBool('upvoted_$postId', false);
        _prefs?.setBool('downvoted_$postId', true);

        notifyListeners();
      } else {
        throw Exception('Failed to downvote post: ${response.body}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> removeUpvote(String postId, {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      _isLoading = true;

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      print('Removing upvote from post $postId on endpoint: $endpoint');

      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/$endpoint/$postId/upvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        final upvotesList = data is Map<String, dynamic>
            ? List<String>.from(data['upvotes'] ?? [])
            : List<String>.from(data['upvotes'] ?? []);
        final downvotesList = data is Map<String, dynamic>
            ? List<String>.from(data['downvotes'] ?? [])
            : List<String>.from(data['downvotes'] ?? []);

        _updateVoteState(postId, upvotesList, downvotesList, userId);
        notifyListeners();
      } else {
        print(
            'Error removing upvote: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to remove upvote');
      }
    } catch (e) {
      print('Error removing upvote: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> removeDownvote(String postId, {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await initializePrefs();
    }

    if (_prefs == null) {
      print('Error: SharedPreferences not initialized');
      return;
    }

    try {
      _isLoading = true;

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      print('Removing downvote from post $postId on endpoint: $endpoint');

      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/v1/$endpoint/$postId/downvote'),
        headers: {
          'Authorization': 'Bearer ${_prefs!.getString('authToken')}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = _prefs!.getString('userId');

        if (userId == null) return;

        final upvotesList = data is Map<String, dynamic>
            ? List<String>.from(data['upvotes'] ?? [])
            : List<String>.from(data['upvotes'] ?? []);
        final downvotesList = data is Map<String, dynamic>
            ? List<String>.from(data['downvotes'] ?? [])
            : List<String>.from(data['downvotes'] ?? []);

        _updateVoteState(postId, upvotesList, downvotesList, userId);
        notifyListeners();
      } else {
        print(
            'Error removing downvote: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to remove downvote');
      }
    } catch (e) {
      print('Error removing downvote: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  bool isUpvoted(String postId) {
    // First check memory state
    if (_upvotedPosts.containsKey(postId)) {
      return _upvotedPosts[postId] ?? false;
    }
    // Then check SharedPreferences
    return _prefs?.getBool('upvoted_$postId') ?? false;
  }

  bool isDownvoted(String postId) {
    // First check memory state
    if (_downvotedPosts.containsKey(postId)) {
      return _downvotedPosts[postId] ?? false;
    }
    // Then check SharedPreferences
    return _prefs?.getBool('downvoted_$postId') ?? false;
  }

  int getUpvoteCount(String postId) {
    // First check memory state
    if (_upvoteCounts.containsKey(postId)) {
      return _upvoteCounts[postId] ?? 0;
    }
    // Then check SharedPreferences
    return _prefs?.getInt('upvotes_$postId') ?? 0;
  }

  int getDownvoteCount(String postId) {
    // First check memory state
    if (_downvoteCounts.containsKey(postId)) {
      return _downvoteCounts[postId] ?? 0;
    }
    // Then check SharedPreferences
    return _prefs?.getInt('downvotes_$postId') ?? 0;
  }
}
