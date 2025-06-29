import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class VendorOrderDetailsScreen extends StatelessWidget {
  const VendorOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(
            color: isDark ? colorScheme.onSurface : Colors.white,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFF2196F3),
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : Colors.white,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
              : [const Color(0xFF2196F3), const Color(0xFF43E97B)],
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
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(Icons.shopping_bag, 'Product', order.productName, isDark, colorScheme),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.person, 'Supplier', order.supplierName, isDark, colorScheme),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.format_list_numbered, 'Quantity', order.quantity.toString(), isDark, colorScheme),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.calendar_today, 'Delivery Date', DateFormat.yMMMd().format(order.preferredDeliveryDate), isDark, colorScheme),
                            if (order.actualDeliveryDate != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.check_circle, 'Delivered', DateFormat.yMMMd().format(order.actualDeliveryDate!), isDark, colorScheme),
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

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.primary.withOpacity(0.2) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: isDark ? colorScheme.primary : Colors.blue.shade700, 
            size: 20
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
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