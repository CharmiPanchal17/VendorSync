// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Mock users for testing
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'vendor@test.com': {
      'name': 'Test Vendor',
      'email': 'vendor@test.com',
      'password': 'password123',
      'role': 'vendor',
      'createdAt': DateTime.now(),
    },
    'supplier@test.com': {
      'name': 'Test Supplier',
      'email': 'supplier@test.com',
      'password': 'password123',
      'role': 'supplier',
      'createdAt': DateTime.now(),
    },
  };

  Future<Map<String, dynamic>?> login(String email, String password, String role) async {
    try {
      // Use mock authentication only (Firebase disabled)
      final user = _mockUsers[email];
      if (user != null && user['password'] == password && user['role'] == role) {
        return user;
      }
      
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    try {
      // Use mock registration only (Firebase disabled)
      if (_mockUsers.containsKey(email)) {
        return false; // User already exists
      }

      _mockUsers[email] = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'createdAt': DateTime.now(),
      };
      
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Get mock users for testing (instance getter)
  Map<String, Map<String, dynamic>> get mockUsers => _mockUsers;
  
  // Get mock users for testing (static getter)
  static Map<String, Map<String, dynamic>> get staticMockUsers => _mockUsers;
} 