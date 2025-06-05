import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      print('🔐 UserProvider initialized:');
      print('📝 Auth Token: ${_authToken != null ? 'Present' : 'Missing'}');
      print('👤 User ID: ${_userId ?? 'Missing'}');
      print('🔑 Is Logged In: $_isLoggedIn');
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
    print('🔐 User logged in:');
    print('👤 User ID: $userId');
    print('📝 Auth Token: ${authToken.isNotEmpty ? 'Present' : 'Missing'}');
    notifyListeners();
  }

  Future<void> logout() async {
    _userId = null;
    _authToken = null;
    _isLoggedIn = false;
    await _prefs?.remove('userId');
    await _prefs?.remove('authToken');
    print('🔐 User logged out');
    notifyListeners();
  }

  Future<void> refreshLoginState() async {
    await _initializePrefs();
  }
}
