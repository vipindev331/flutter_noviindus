import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Auth
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_keyToken, token);
  }

  static String? getToken() => _prefs?.getString(_keyToken);

  static Future<void> saveUserId(String userId) async {
    await _prefs?.setString(_keyUserId, userId);
  }

  static String? getUserId() => _prefs?.getString(_keyUserId);

  static Future<void> setLoggedIn(bool value) async {
    await _prefs?.setBool(_keyIsLoggedIn, value);
  }

  static bool isLoggedIn() => _prefs?.getBool(_keyIsLoggedIn) ?? false;

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
