// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthService {
//   static final AuthService _instance = AuthService._internal();
//   factory AuthService() => _instance;
//   AuthService._internal();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<Map<String, dynamic>?> login(String email, String password, String role) async {
//     try {
//       // Query Firestore for user
//       final query = await _firestore.collection(role == 'vendor' ? 'vendors' : 'suppliers')
//         .where('email', isEqualTo: email)
//         .where('password', isEqualTo: password)
//         .limit(1)
//         .get();
//       if (query.docs.isNotEmpty) {
//         return query.docs.first.data();
//       }
//       return null;
//     } catch (e) {
//       print('Login error: $e');
//       return null;
//     }
//   }

//   Future<bool> register(String name, String email, String password, String role) async {
//     try {
//       // Check if user already exists
//       final existing = await _firestore.collection(role == 'vendor' ? 'vendors' : 'suppliers')
//         .where('email', isEqualTo: email)
//         .get();
//       if (existing.docs.isNotEmpty) {
//         return false;
//       }

//       final userData = {
//         'name': name,
//         'email': email,
//         'password': password, // (You should hash passwords in production)
//         'role': role, // Ensure role is set
//         'createdAt': FieldValue.serverTimestamp(),
//       };

//       await _firestore.collection(role == 'vendor' ? 'vendors' : 'suppliers').add(userData);
//       return true;
//     } catch (e) {
//       print('Registration error: $e');
//       return false;
//     }
//   }
// } 

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Don't initialize this early:
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> login(String email, String password, String role) async {
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized from login()');
      }
      final firestore = FirebaseFirestore.instance;

      final query = await firestore
          .collection(role == 'vendor' ? 'vendors' : 'suppliers')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> register(String name, String email, String password, String role) async {
    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized from register()');
      }
      final firestore = FirebaseFirestore.instance;

      final existing = await firestore
          .collection(role == 'vendor' ? 'vendors' : 'suppliers')
          .where('email', isEqualTo: email)
          .get();

      if (existing.docs.isNotEmpty) {
        return false;
      }

      final userData = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection(role == 'vendor' ? 'vendors' : 'suppliers')
          .add(userData);
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
}
