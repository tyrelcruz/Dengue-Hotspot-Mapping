import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:buzzmap/auth/config.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/errors/flushbar.dart';

class OfflinePostService {
  static final OfflinePostService _instance = OfflinePostService._internal();
  factory OfflinePostService() => _instance;
  OfflinePostService._internal();

  final Connectivity _connectivity = Connectivity();
  Timer? _retryTimer;
  Timer? _debounceTimer;
  bool _isRetrying = false;
  BuildContext? _lastContext;
  DateTime? _lastConnectivityCheck;
  bool _isOnline = false;
  StreamSubscription? _connectivitySubscription;

  // Stream controller for offline posts count
  final _offlinePostsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get offlinePostsStream =>
      _offlinePostsController.stream;

  Future<void> initialize(BuildContext context) async {
    _lastContext = context;
    bool isCheckingPosts = false;

    // Cancel any existing subscription
    await _connectivitySubscription?.cancel();

    // Set up connectivity listener with proper debouncing
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final now = DateTime.now();

      // Debounce connectivity checks - only allow one check every 5 seconds
      if (_lastConnectivityCheck != null &&
          now.difference(_lastConnectivityCheck!) <
              const Duration(seconds: 5)) {
        return;
      }
      _lastConnectivityCheck = now;

      // Update online status
      final isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      if (_isOnline != isOnline) {
        _isOnline = isOnline;

        // Only proceed if we're online and not already checking posts
        if (_isOnline && !isCheckingPosts) {
          isCheckingPosts = true;
          try {
            final posts = await getOfflinePosts();
            if (posts.isNotEmpty &&
                _lastContext != null &&
                _lastContext!.mounted) {
              // Add a small delay to ensure the app is fully initialized
              await Future.delayed(const Duration(seconds: 1));
              if (_lastContext != null && _lastContext!.mounted) {
                // Double check we're still online before showing dialog
                final currentConnectivity =
                    await _connectivity.checkConnectivity();
                if (currentConnectivity != ConnectivityResult.none) {
                  _showSyncConfirmationDialog(_lastContext!, posts.length);
                }
              }
            }
          } finally {
            isCheckingPosts = false;
          }
        }
      }
    });

    // Check initial connectivity and offline posts
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      if (_isOnline) {
        final posts = await getOfflinePosts();
        if (posts.isNotEmpty && _lastContext != null && _lastContext!.mounted) {
          _showSyncConfirmationDialog(_lastContext!, posts.length);
        }
      }
    } catch (e) {
      print('Error checking initial connectivity: $e');
    }
  }

  void updateContext(BuildContext context) {
    _lastContext = context;
  }

  Future<void> _showSyncConfirmationDialog(
      BuildContext context, int postCount) async {
    if (!context.mounted) return;

    // Double check connectivity before showing dialog
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

    // Check if there are still posts to sync
    final posts = await getOfflinePosts();
    if (posts.isEmpty) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pending Reports Found'),
          content: Text(
              'You have $postCount pending report${postCount > 1 ? 's' : ''} that can be synced now. Would you like to upload them?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _syncOfflinePosts(context);
              },
              child: const Text('Sync Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncOfflinePosts(BuildContext context) async {
    final posts = await getOfflinePosts();
    if (posts.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Debug: Starting sync with ${posts.length} posts');
    print('Debug: Auth token available: ${token != null}');
    print('Debug: Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
    print('Debug: Using base URL: ${Config.baseUrl}');

    int successCount = 0;
    int failCount = 0;
    List<int> successfulIndices = [];
    Set<String> processedPosts =
        {}; // Track processed posts to prevent duplicates

    // Show initial sync message
    if (context.mounted) {
      await AppFlushBar.showInfo(
        context,
        title: 'Syncing Reports',
        message:
            'Starting to sync ${posts.length} report${posts.length > 1 ? 's' : ''}...',
        duration: const Duration(seconds: 2),
      );
    }

    for (int i = 0; i < posts.length; i++) {
      final post = posts[i];

      // Create a unique identifier for this post
      final postIdentifier =
          '${post['barangay']}_${post['report_type']}_${post['date_and_time']}_${post['specific_location']['coordinates'][0]}_${post['specific_location']['coordinates'][1]}';

      // Skip if we've already processed this post
      if (processedPosts.contains(postIdentifier)) {
        print('Debug: Skipping duplicate post: $postIdentifier');
        successfulIndices.add(i); // Mark for removal since it's a duplicate
        continue;
      }

      processedPosts.add(postIdentifier);

      try {
        print('Debug: Attempting to sync post ${i + 1}/${posts.length}');
        print('Debug: Post identifier: $postIdentifier');
        final url = Uri.parse(Config.createPostUrl);
        print('Debug: Using URL: ${url.toString()}');

        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';
        print('Debug: Request headers: ${request.headers}');

        request.fields.addAll({
          'barangay': post['barangay'] as String,
          'report_type': post['report_type'] as String,
          'description': post['description'] as String,
          'date_and_time': post['date_and_time'] as String,
          'specific_location[type]': (post['specific_location']
              as Map<String, dynamic>)['type'] as String,
          'specific_location[coordinates][0]': (post['specific_location']
                  as Map<String, dynamic>)['coordinates'][0]
              .toString(),
          'specific_location[coordinates][1]': (post['specific_location']
                  as Map<String, dynamic>)['coordinates'][1]
              .toString(),
        });

        // Handle images if they exist
        if (post['images'] != null) {
          final List<dynamic> imagePaths = post['images'] as List<dynamic>;
          for (final imagePath in imagePaths) {
            if (imagePath != null && imagePath.toString().isNotEmpty) {
              try {
                final image = await http.MultipartFile.fromPath(
                    'images', imagePath.toString());
                request.files.add(image);
              } catch (e) {
                print('Debug: Error adding image: $e');
              }
            }
          }
        }

        print('Debug: Sending request for post $postIdentifier');
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        print('Debug: Response status code: ${response.statusCode}');
        print('Debug: Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          successfulIndices.add(i);
          successCount++;
          print('Debug: Successfully synced post $postIdentifier');

          // Show progress message for this post
          if (context.mounted) {
            final reportType = post['report_type'] as String? ?? 'Report';
            final barangay = post['barangay'] as String? ?? 'Unknown Location';
            await AppFlushBar.showSuccess(
              context,
              title: 'Report Uploaded',
              message:
                  'Your $reportType in $barangay has been successfully uploaded.',
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          failCount++;
          print(
              'Debug: Failed to sync post $postIdentifier. Status code: ${response.statusCode}');
          throw Exception('Failed to sync post: ${response.statusCode}');
        }
      } catch (e) {
        failCount++;
        print('Debug: Error syncing post $postIdentifier: $e');
        // Show error for this specific post
        if (context.mounted) {
          final reportType = post['report_type'] as String? ?? 'Report';
          final barangay = post['barangay'] as String? ?? 'Unknown Location';
          await AppFlushBar.showError(
            context,
            title: 'Upload Failed',
            message:
                'Unable to upload your $reportType in $barangay. We\'ll try again later.',
            duration: const Duration(seconds: 3),
          );
        }
      }
    }

    print('Debug: Sync complete. Success: $successCount, Failed: $failCount');
    print('Debug: Removing ${successfulIndices.length} successful posts');

    // Remove all successfully synced posts at once
    if (successfulIndices.isNotEmpty) {
      // Sort indices in descending order to avoid index shifting issues
      successfulIndices.sort((a, b) => b.compareTo(a));
      for (final index in successfulIndices) {
        await removeOfflinePost(index);
      }
    }

    // Show final status with a more user-friendly message
    if (context.mounted) {
      final remainingPosts = await getOfflinePosts();
      print('Debug: Remaining posts after sync: ${remainingPosts.length}');

      if (remainingPosts.isEmpty) {
        await AppFlushBar.showSuccess(
          context,
          title: 'All Reports Uploaded',
          message:
              'Great! All your reports have been successfully uploaded to the server.',
          duration: const Duration(seconds: 3),
        );
      } else {
        String message;
        if (successCount > 0 && failCount > 0) {
          message =
              '$successCount report${successCount > 1 ? 's' : ''} uploaded successfully, but $failCount failed. We\'ll try uploading the failed reports again when you\'re back online.';
        } else if (failCount > 0) {
          message =
              'Unable to upload $failCount report${failCount > 1 ? 's' : ''}. We\'ll try again when you\'re back online.';
        } else {
          message =
              'Some reports are still pending. We\'ll try uploading them again when you\'re back online.';
        }

        await AppFlushBar.showInfo(
          context,
          title: 'Partial Upload Complete',
          message: message,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getOfflinePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString('offline_posts');
      if (postsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(postsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting offline posts: $e');
      return [];
    }
  }

  Future<void> addOfflinePost(Map<String, dynamic> postData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPosts = await getOfflinePosts();

      // Create a new map with proper type casting
      final Map<String, dynamic> sanitizedData = {
        'barangay': postData['barangay']?.toString(),
        'report_type': postData['report_type']?.toString(),
        'description': postData['description']?.toString(),
        'date_and_time': postData['date_and_time']?.toString(),
        'specific_location': {
          'type':
              (postData['specific_location'] as Map<String, dynamic>)['type']
                  ?.toString(),
          'coordinates': [
            (postData['specific_location']
                    as Map<String, dynamic>)['coordinates'][0]
                ?.toString(),
            (postData['specific_location']
                    as Map<String, dynamic>)['coordinates'][1]
                ?.toString(),
          ],
        },
      };

      // Handle images separately
      if (postData['images'] != null) {
        final List<dynamic> imagePaths = postData['images'] as List<dynamic>;
        sanitizedData['images'] = imagePaths
            .where((path) => path != null)
            .map((path) => path.toString())
            .toList();
      } else {
        sanitizedData['images'] = [];
      }

      existingPosts.add(sanitizedData);
      await prefs.setString('offline_posts', jsonEncode(existingPosts));
      _offlinePostsController.add(existingPosts);
    } catch (e) {
      print('Error saving offline post: $e');
      rethrow;
    }
  }

  Future<void> removeOfflinePost(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final posts = await getOfflinePosts();
      if (index >= 0 && index < posts.length) {
        posts.removeAt(index);
        await prefs.setString('offline_posts', jsonEncode(posts));
        _offlinePostsController.add(posts);
      }
    } catch (e) {
      print('Error removing offline post: $e');
      rethrow;
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _offlinePostsController.close();
  }
}
