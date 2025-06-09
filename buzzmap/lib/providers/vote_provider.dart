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
      if (userId == null) {
        print(
            'VoteProvider: No user ID available, initializing with default states');
        return;
      }

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

          final upvotesList = List<dynamic>.from(post['upvotes'] ?? []);
          final downvotesList = List<dynamic>.from(post['downvotes'] ?? []);

          // Initialize vote states with default values if not present
          _upvotedPosts[postId] = _upvotedPosts[postId] ?? false;
          _downvotedPosts[postId] = _downvotedPosts[postId] ?? false;
          _upvoteCounts[postId] = post['upvoteCount'] ?? upvotesList.length;
          _downvoteCounts[postId] =
              post['downvoteCount'] ?? downvotesList.length;

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

            final upvotesList = List<dynamic>.from(post['upvotes'] ?? []);
            final downvotesList = List<dynamic>.from(post['downvotes'] ?? []);

            _updateVoteState(postId, upvotesList, downvotesList, userId);
          }
        }
      }
    } catch (e) {
      print('VoteProvider: Error loading vote states: $e');
    } finally {
      _isLoadingAllVotes = false;
      notifyListeners();
    }
  }

  void _updateVoteState(String postId, List<dynamic> upvotesList,
      List<dynamic> downvotesList, String userId) {
    // Convert upvotes and downvotes to list of user IDs
    final upvoteIds = upvotesList
        .map((vote) => vote is Map ? vote['_id']?.toString() : vote.toString())
        .where((id) => id != null)
        .toList();

    final downvoteIds = downvotesList
        .map((vote) => vote is Map ? vote['_id']?.toString() : vote.toString())
        .where((id) => id != null)
        .toList();

    _upvotedPosts[postId] = upvoteIds.contains(userId);
    _downvotedPosts[postId] = downvoteIds.contains(userId);
    _upvoteCounts[postId] = upvoteIds.length;
    _downvoteCounts[postId] = downvoteIds.length;

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

    // Always fetch the latest state from the backend for this postId
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

        // If the backend wraps the data in a 'data' field, use that
        final postData = data['data'] ?? data;

        print('VoteProvider: backend response for $postId: $data');

        if (userId == null) {
          return;
        }

        // Update vote counts from response, fallback to array length if needed
        _upvoteCounts[postId] =
            postData['upvoteCount'] ?? (postData['upvotes']?.length ?? 0);
        _downvoteCounts[postId] =
            postData['downvoteCount'] ?? (postData['downvotes']?.length ?? 0);

        print(
            'VoteProvider: updated counts for $postId: upvotes=${_upvoteCounts[postId]}, downvotes=${_downvoteCounts[postId]}');

        // Update vote state
        _upvotedPosts[postId] = postData['upvotes']?.contains(userId) ?? false;
        _downvotedPosts[postId] =
            postData['downvotes']?.contains(userId) ?? false;

        // Store in SharedPreferences
        _prefs?.setInt('upvotes_$postId', _upvoteCounts[postId] ?? 0);
        _prefs?.setInt('downvotes_$postId', _downvoteCounts[postId] ?? 0);
        _prefs?.setBool('upvoted_$postId', _upvotedPosts[postId] ?? false);
        _prefs?.setBool('downvoted_$postId', _downvotedPosts[postId] ?? false);

        notifyListeners();
      }
    } catch (e) {
      // Silent error handling
      print('VoteProvider: error fetching vote status for $postId: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> upvotePost(String postId, {bool isAdminPost = false}) async {
    if (!_isInitialized) {
      await initializePrefs();
    }

    if (_prefs == null) {
      print('VoteProvider: SharedPreferences not initialized');
      return;
    }

    try {
      _isLoading = true;
      final token = _prefs!.getString('authToken');
      final userId = _prefs!.getString('userId');

      print('VoteProvider: Attempting to upvote post $postId');
      print('VoteProvider: Auth token present: ${token != null}');
      print('VoteProvider: User ID: $userId');

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
      final url = '${Config.baseUrl}/api/v1/$endpoint/$postId/upvote';
      print('VoteProvider: Calling endpoint: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('VoteProvider: Response status code: ${response.statusCode}');
      print('VoteProvider: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (userId == null) {
          print('VoteProvider: No user ID found');
          return;
        }

        // Debug prints
        print('VoteProvider upvotePost response: $data');
        print(
            'VoteProvider upvotePost before update: upvotes=${_upvoteCounts[postId]}, downvotes=${_downvoteCounts[postId]}');

        // Update vote counts from response
        _upvoteCounts[postId] =
            data['upvoteCount'] ?? (data['upvotes']?.length ?? 0);
        _downvoteCounts[postId] =
            data['downvoteCount'] ?? (data['downvotes']?.length ?? 0);

        print(
            'VoteProvider upvotePost after update: upvotes=${_upvoteCounts[postId]}, downvotes=${_downvoteCounts[postId]}');

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
        print(
            'VoteProvider: Failed to upvote. Status code: ${response.statusCode}');
        print('VoteProvider: Response body: ${response.body}');
        throw Exception('Failed to upvote post: ${response.body}');
      }
    } catch (e) {
      print('Error upvoting post: $e');
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
        _upvoteCounts[postId] = data['upvoteCount'] ?? 0;
        _downvoteCounts[postId] = data['downvoteCount'] ?? 0;

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
      print('Error downvoting post: $e');
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
      return;
    }

    try {
      _isLoading = true;

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
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

        // Update vote counts from response
        _upvoteCounts[postId] = data['upvoteCount'] ?? 0;
        _downvoteCounts[postId] = data['downvoteCount'] ?? 0;

        // Update vote state
        _upvotedPosts[postId] = false;

        // Store in SharedPreferences
        _prefs?.setInt('upvotes_$postId', _upvoteCounts[postId] ?? 0);
        _prefs?.setInt('downvotes_$postId', _downvoteCounts[postId] ?? 0);
        _prefs?.setBool('upvoted_$postId', false);

        notifyListeners();
      } else {
        throw Exception('Failed to remove upvote: ${response.body}');
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
      return;
    }

    try {
      _isLoading = true;

      final endpoint = isAdminPost ? 'adminPosts' : 'reports';
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

        // Update vote counts from response
        _upvoteCounts[postId] = data['upvoteCount'] ?? 0;
        _downvoteCounts[postId] = data['downvoteCount'] ?? 0;

        // Update vote state
        _downvotedPosts[postId] = false;

        // Store in SharedPreferences
        _prefs?.setInt('upvotes_$postId', _upvoteCounts[postId] ?? 0);
        _prefs?.setInt('downvotes_$postId', _downvoteCounts[postId] ?? 0);
        _prefs?.setBool('downvoted_$postId', false);

        notifyListeners();
      } else {
        throw Exception('Failed to remove downvote: ${response.body}');
      }
    } catch (e) {
      print('Error removing downvote: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  bool isUpvoted(String postId) {
    if (!_isInitialized || _prefs == null) return false;
    return _upvotedPosts[postId] ?? false;
  }

  bool isDownvoted(String postId) {
    if (!_isInitialized || _prefs == null) return false;
    return _downvotedPosts[postId] ?? false;
  }

  int getUpvoteCount(String postId) {
    if (!_isInitialized || _prefs == null) return 0;
    return _upvoteCounts[postId] ?? 0;
  }

  int getDownvoteCount(String postId) {
    if (!_isInitialized || _prefs == null) return 0;
    return _downvoteCounts[postId] ?? 0;
  }

  Future<void> clearUserVotes() async {
    // Clear in-memory state
    _upvoteCounts.clear();
    _downvoteCounts.clear();
    _upvotedPosts.clear();
    _downvotedPosts.clear();

    // Clear SharedPreferences for votes
    if (_prefs != null) {
      final keys = _prefs!
          .getKeys()
          .where((key) =>
              key.startsWith('upvotes_') ||
              key.startsWith('downvotes_') ||
              key.startsWith('upvoted_') ||
              key.startsWith('downvoted_'))
          .toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
    // Ensure listeners are notified and UI is rebuilt with cleared state
    notifyListeners();
  }
}
