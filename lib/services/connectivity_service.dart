import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../screens/offline_screen.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void initializeConnectivityMonitoring(BuildContext context) {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOnline && !_isOnline) {
        // Just went offline
        _showOfflineScreen(context);
      } else if (!wasOnline && _isOnline) {
        // Just came back online
        _hideOfflineScreen(context);
      }
    });
  }

  void _showOfflineScreen(BuildContext context) {
    // Check if offline screen is already showing
    if (ModalRoute.of(context)?.settings.name != '/offline') {
      Navigator.of(context).pushNamed('/offline');
    }
  }

  void _hideOfflineScreen(BuildContext context) {
    // Check if we're on the offline screen and go back
    if (ModalRoute.of(context)?.settings.name == '/offline') {
      Navigator.of(context).pop();
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }
} 