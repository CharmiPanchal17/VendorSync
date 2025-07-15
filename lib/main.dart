import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/vendor/edit_profile_screen.dart';
import 'screens/supplier/edit_profile_screen.dart';
import 'screens/vendor/settings_screen.dart';
import 'screens/supplier/settings_screen.dart';

import 'models/order.dart' as order_model;
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  final storage = FlutterSecureStorage();
  String? userEmail = await storage.read(key: 'userEmail');
  String? loginTimestampStr = await storage.read(key: 'loginTimestamp');
  bool isSessionValid = false;
  if (userEmail != null && loginTimestampStr != null) {
    final loginTimestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(loginTimestampStr));
    final now = DateTime.now();
    if (now.difference(loginTimestamp).inDays < 6) {
      isSessionValid = true;
    } else {
      // Session expired, clear storage
      await storage.delete(key: 'userEmail');
      await storage.delete(key: 'loginTimestamp');
    }
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
          }
        }
        return const SplashScreen();
      },
    );
  }
}
