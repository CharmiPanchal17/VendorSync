import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
      body: SafeArea(
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Center(
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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your all-in-one Vendor-to-Supplier Management System',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Vendor Register', style: TextStyle(fontSize: 18)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => Navigator.of(context).pushNamed('/register'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Supplier Login', style: TextStyle(fontSize: 18)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => Navigator.of(context).pushNamed('/login', arguments: 'supplier'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 