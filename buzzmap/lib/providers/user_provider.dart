import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/vote_provider.dart';
import 'package:buzzmap/services/notification_service.dart';

class UserProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _authToken;
  SharedPreferences? _prefs;

  UserProvider() {
    _initializePrefs();
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get authToken => _authToken;

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _authToken = _prefs!.getString('authToken');
      _userId = _prefs!.getString('userId');
      _isLoggedIn = _authToken != null &&
          _userId != null &&
          _authToken!.isNotEmpty &&
          _userId!.isNotEmpty;

      notifyListeners();
    } catch (e) {
      print('Error initializing UserProvider: $e');
    }
  }

  Future<void> setLoggedIn(String userId, String authToken) async {
    _userId = userId;
    _authToken = authToken;
    _isLoggedIn = true;
    await _prefs?.setString('userId', userId);
    await _prefs?.setString('authToken', authToken);

    notifyListeners();
  }

  Future<void> logout(context) async {
    _userId = null;
    _authToken = null;
    _isLoggedIn = false;
    await _prefs?.remove('userId');
    await _prefs?.remove('authToken');
    // Clear votes and notifications
    try {
      await Provider.of<VoteProvider>(context, listen: false).clearUserVotes();
    } catch (e) {
      print('Error clearing votes on logout: $e');
    }
    try {
      await Provider.of<NotificationService>(context, listen: false)
          .clearUserNotifications();
    } catch (e) {
      print('Error clearing notifications on logout: $e');
    }

    notifyListeners();
  }

  Future<void> refreshLoginState() async {
    await _initializePrefs();
  }
}
