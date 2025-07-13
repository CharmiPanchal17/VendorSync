import 'package:flutter/material.dart';
import 'dart:async';
import '../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Add a minimum delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      // Check if user has a valid session
      final isLoggedIn = await SessionService.isLoggedIn();
      
      if (isLoggedIn) {
        // User has a valid session, get their role and redirect to appropriate dashboard
        final userRole = await SessionService.getUserRole();
        final userEmail = await SessionService.getUserEmail();
        
        if (userRole == 'vendor' && userEmail != null) {
          Navigator.of(context).pushReplacementNamed('/vendor-dashboard', arguments: userEmail);
        } else if (userRole == 'supplier' && userEmail != null) {
          Navigator.of(context).pushReplacementNamed('/supplier-dashboard', arguments: userEmail);
        } else {
          // Invalid session data, clear it and redirect to welcome screen
          await SessionService.clearSession();
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      } else {
        // No valid session, redirect to welcome screen
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } catch (e) {
      // Error occurred, clear any corrupted session data and redirect to welcome screen
      try {
        await SessionService.clearSession();
      } catch (clearError) {
        // Ignore errors when clearing session
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.sync,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VendorSync',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
    );
  }
} 