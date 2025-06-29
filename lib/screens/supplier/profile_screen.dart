import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierProfileScreen extends StatefulWidget {
  final String supplierEmail;
  const SupplierProfileScreen({super.key, required this.supplierEmail});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  Map<String, dynamic>? supplierData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSupplierData();
  }

  Future<void> _fetchSupplierData() async {
    try {
      final supplierQuery = await FirebaseFirestore.instance
          .collection('suppliers')
          .where('email', isEqualTo: widget.supplierEmail)
          .limit(1)
          .get();
      if (supplierQuery.docs.isNotEmpty) {
        setState(() {
          supplierData = supplierQuery.docs.first.data();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Supplier not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load supplier data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSupplierData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final String supplierName = supplierData?['name'] ?? 'Unknown Supplier';
    final String email = supplierData?['email'] ?? widget.supplierEmail;
    final String phone = supplierData?['phone'] ?? 'Not provided';
    final String company = supplierData?['company'] ?? 'Not specified';
    final Timestamp? createdAt = supplierData?['createdAt'];
    final String createdDate = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : 'Unknown';
    // Mock stat for now
    final int totalOrders = 58;

    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Profile')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF43E97B), // Green
              Color(0xFF38F9D7), // Lighter green/teal
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.local_shipping, size: 48, color: Colors.green),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          supplierName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade300),
                        _buildInfoRow(Icons.email, 'Email', email),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.phone, 'Phone', phone),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.calendar_today, 'Account Created', createdDate),
                        const SizedBox(height: 24),
                        _buildStatCard('Orders Fulfilled', totalOrders, Colors.green),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 