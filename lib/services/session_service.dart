import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _sessionKey = 'user_session';
  static const String _lastActivityKey = 'last_activity';
  static const int _sessionDurationDays = 14;

  // Save user session data
  static Future<void> saveSession({
    required String email,
    required String role,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = {
      'email': email,
      'role': role,
      'userId': userId,
      'loginTime': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_sessionKey, jsonEncode(sessionData));
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Get current session data
  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionString = prefs.getString(_sessionKey);
    
    if (sessionString == null) return null;
    
    try {
      final sessionData = jsonDecode(sessionString) as Map<String, dynamic>;
      
      // Check if session is still valid (within 14 days)
      final loginTime = DateTime.parse(sessionData['loginTime']);
      final daysSinceLogin = DateTime.now().difference(loginTime).inDays;
      
      if (daysSinceLogin >= _sessionDurationDays) {
        // Session expired, clear it
        await clearSession();
        return null;
      }
      
      // Check if session should be extended based on last activity
      final shouldExtend = await shouldExtendSession();
      if (shouldExtend) {
        await extendSession();
      }
      
      // Update last activity time
      await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
      
      return sessionData;
    } catch (e) {
      // Invalid session data, clear it
      await clearSession();
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null;
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final session = await getSession();
    return session?['role'];
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final session = await getSession();
    return session?['email'];
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final session = await getSession();
    return session?['userId'];
  }

  // Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_lastActivityKey);
  }

  // Update last activity (called when user interacts with the app)
  static Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  // Check if session should be extended (user is active within 14 days)
  static Future<bool> shouldExtendSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString(_lastActivityKey);
    
    if (lastActivityString == null) return false;
    
    try {
      final lastActivity = DateTime.parse(lastActivityString);
      final daysSinceLastActivity = DateTime.now().difference(lastActivity).inDays;
      
      // If user was active within the last 14 days, extend session
      return daysSinceLastActivity < _sessionDurationDays;
    } catch (e) {
      return false;
    }
  }

  // Extend session by updating login time
  static Future<void> extendSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionString = prefs.getString(_sessionKey);
    
    if (sessionString != null) {
      try {
        final sessionData = jsonDecode(sessionString) as Map<String, dynamic>;
        sessionData['loginTime'] = DateTime.now().toIso8601String();
        
        await prefs.setString(_sessionKey, jsonEncode(sessionData));
        await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
      } catch (e) {
        // If there's an error, clear the session
        await clearSession();
      }
    }
  }
} 