import 'package:flutter/material.dart';
import '../../models/order.dart' as order_model;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierOrderDetailsScreen extends StatefulWidget {
  const SupplierOrderDetailsScreen({super.key});

  @override
  State<SupplierOrderDetailsScreen> createState() => _SupplierOrderDetailsScreenState();
}

class _SupplierOrderDetailsScreenState extends State<SupplierOrderDetailsScreen> {
  String? status;
  DateTime? deliveryDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as order_model.Order;
    status ??= order.status;
    deliveryDate ??= order.actualDeliveryDate;

    // Ensure status matches available options
    final availableOptions = _getAvailableStatusOptions(order.status);
    if (availableOptions.isNotEmpty && !availableOptions.any((item) => item.value == status)) {
      status = availableOptions.first.value;
    }
    if (availableOptions.isEmpty) {
      status = null;
    }
    
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF43E97B),
                  Color(0xFF38F9D7),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(Icons.inventory, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.productName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          Text(
                                            'Order ID: ${order.id}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow('Vendor', order.supplierName),
                                _buildDetailRow('Quantity', order.quantity.toString()),
                                _buildDetailRow(
                                  'Preferred Delivery',
                                  DateFormat.yMMMd().format(order.preferredDeliveryDate),
                                ),
                                if (order.status != 'Pending Approval')
                                  _buildDetailRow('Current Status', order.status),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update Order Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_getAvailableStatusOptions(order.status).isEmpty && order.status != 'Pending Approval') ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(order.status).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(order.status),
                                          color: _getStatusColor(order.status),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Current Status: ${order.status}',
                                          style: TextStyle(
                                            color: _getStatusColor(order.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.white, Colors.grey.shade50],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Order Status',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.assignment, color: Colors.white, size: 20),
                                      ),
                                    ),
                                    value: _getAvailableStatusOptions(order.status).isNotEmpty ? status : null,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                    ),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    items: [
                                      ..._getAvailableStatusOptions(order.status),
                                    ],
                                    onChanged: _getAvailableStatusOptions(order.status).isEmpty 
                                        ? null 
                                        : (val) {
                                            if (val != null) {
                                              setState(() => status = val);
                                            }
                                          },
                                    hint: _getAvailableStatusOptions(order.status).isEmpty 
                                        ? Text(
                                            'No further updates',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            maxLines: 1,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                    ),
                                    title: Text(
                                      deliveryDate == null
                      ? 'Set Delivery Date'
                                          : 'Delivery Date: ${DateFormat.yMMMd().format(deliveryDate!)}',
                                      style: TextStyle(
                                        color: deliveryDate == null ? Colors.grey.shade600 : Colors.black,
                                        fontWeight: deliveryDate == null ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: const ColorScheme.light(
                                                primary: Color(0xFF43E97B),
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                        );
                        if (picked != null) {
                          setState(() => deliveryDate = picked);
                        }
                      },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43E97B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _isLoading || _getAvailableStatusOptions(order.status).isEmpty 
                                  ? null 
                                  : () => _showUpdateConfirmation(order.id),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _getAvailableStatusOptions(order.status).isEmpty 
                                          ? 'No Updates Available'
                                          : 'Update Order',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _getAvailableStatusOptions(order.status).isEmpty 
                                            ? Colors.grey.shade600 
                                            : Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrder(String orderId) async {
    if (status == null) {
      setState(() {
        _errorMessage = 'Please select a status';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status,
        if (deliveryDate != null) 'actualDeliveryDate': deliveryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
                Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update order. Please try again.';
      });
    }
  }

  Future<void> _showUpdateConfirmation(String orderId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.update, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Update Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to update the order?'),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status ?? 'Pending'),
              ),
            ),
            if (deliveryDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Delivery Date: ${DateFormat.yMMMd().format(deliveryDate!)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43E97B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrder(orderId);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Pending Approval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<DropdownMenuItem<String>> _getAvailableStatusOptions(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return [
          DropdownMenuItem(
            value: 'Confirmed',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.blue, size: 16),
                ),
                const SizedBox(width: 12),
                const Text('Confirmed'),
              ],
            ),
          ),
        ];
      case 'Confirmed':
        return [
          DropdownMenuItem(
            value: 'Pending Approval',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.pending_actions, color: Colors.purple, size: 16),
                ),
                const SizedBox(width: 12),
                const Text('Pending Approval'),
              ],
            ),
          ),
        ];
      default:
        return [];
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'Confirmed':
        return Icons.check_circle;
      case 'Delivered':
        return Icons.local_shipping;
      case 'Pending Approval':
        return Icons.pending_actions;
      default:
        return Icons.info;
    }
  }
}
