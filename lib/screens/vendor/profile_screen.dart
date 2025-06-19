import 'package:flutter/material.dart';

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Profile')),
      body: const Center(
        child: Text('Vendor profile details here.'),
      ),
    );
  }
} 