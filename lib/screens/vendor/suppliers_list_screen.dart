import 'package:flutter/material.dart';
import 'available_suppliers_screen.dart';

class SuppliersListScreen extends StatelessWidget {
  final String vendorEmail;
  const SuppliersListScreen({super.key, required this.vendorEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Suppliers'),
      ),
      body: Column(
        children: [
          // Section for My Suppliers
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: const Text(
              'My Suppliers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Section for Available Suppliers
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: const Text(
              'Available Suppliers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AvailableSuppliersScreen(vendorEmail: vendorEmail),
            ),
          );
        },
        tooltip: 'Add Supplier',
        child: const Icon(Icons.add),
      ),
    );
  }
} 