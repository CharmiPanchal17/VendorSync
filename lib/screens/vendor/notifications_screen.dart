import 'package:flutter/material.dart';

class VendorNotificationsScreen extends StatelessWidget {
  final String vendorEmail;
  
  const VendorNotificationsScreen({super.key, required this.vendorEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('Notifications page'),
      ),
    );
  }
} 