import 'package:flutter/material.dart';

class SupplierNotificationsScreen extends StatelessWidget {
  const SupplierNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(
        child: Text('No notifications yet.'),
      ),
    );
  }
} 