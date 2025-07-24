import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class VendorOrderDetailsScreen extends StatelessWidget {
  const VendorOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3), // Blue
              Color(0xFF43E97B), // Green
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Card with order info
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 8,
                      color: Colors.white.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(Icons.shopping_bag, 'Product', order.productName),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.person, 'Supplier', order.supplierName),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.format_list_numbered, 'Quantity', order.quantity.toString()),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.calendar_today, 'Delivery Date', DateFormat.yMMMd().format(order.preferredDeliveryDate)),
                            if (order.actualDeliveryDate != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.check_circle, 'Delivered', DateFormat.yMMMd().format(order.actualDeliveryDate!)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Status Chip
                    Center(
                      child: Chip(
                        label: Text(
                          order.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        backgroundColor: _getStatusColor(order.status),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 4,
                      ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
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

  int _statusIndex(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'Confirmed':
        return 1;
      case 'Shipped':
        return 2;
      case 'Delivered':
        return 3;
      default:
        return 0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 