import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          // Solid light cyan background
          Container(
            color: const Color(0xFFAFFFFF),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0, // No shadow
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  color: Colors.transparent, // Fully transparent
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.sync, size: 56, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Welcome to VendorSync',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD50060),
                            fontSize: 36,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your all-in-one Vendor-to-Supplier Management System',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Color(0xFF333333)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            child: const Text('Vendor Register', style: TextStyle(fontSize: 18)),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: const Color(0xFFD50060), // Magenta
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              elevation: 2,
                            ),
                            onPressed: () => Navigator.of(context).pushNamed('/register'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            child: const Text('Supplier Register', style: TextStyle(fontSize: 18)),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: const Color(0xFFD50060), // Magenta
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              elevation: 2,
                            ),
                            onPressed: () => Navigator.of(context).pushNamed('/register-supplier'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 