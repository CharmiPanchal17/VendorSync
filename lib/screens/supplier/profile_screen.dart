import 'package:flutter/material.dart';

class SupplierProfileScreen extends StatelessWidget {
  const SupplierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Profile')),
      body: const Center(
        child: Text('Supplier profile details here.'),
      ),
    );
  }
} 