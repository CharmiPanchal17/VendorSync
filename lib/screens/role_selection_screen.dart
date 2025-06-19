import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.store),
              label: const Text('Vendor'),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/vendor-dashboard');
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping),
              label: const Text('Supplier'),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/supplier-dashboard');
              },
            ),
          ],
        ),
      ),
    );
  }
} 