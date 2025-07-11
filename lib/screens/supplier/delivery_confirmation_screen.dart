import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/notification_service.dart';
import '../../services/delivery_tracking_service.dart';

const maroonDelivery = Color(0xFF800000);
const lightCyanDelivery = Color(0xFFAFFFFF);

class DeliveryConfirmationScreen extends StatefulWidget {
  final Order order;
  
  const DeliveryConfirmationScreen({super.key, required this.order});

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _deliveryDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Delivery'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
                                colors: isDark
                      ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                      : [maroonDelivery, maroonDelivery.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyanDelivery,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                _buildOrderSummaryCard(isDark),
                const SizedBox(height: 24),
                
                // Delivery Details Form
                _buildDeliveryForm(isDark),
                const SizedBox(height: 32),
                
                // Submit Button
                _buildSubmitButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: maroonDelivery.withOpacity(0.2),
                  child: Icon(Icons.shopping_cart, color: maroonDelivery),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.order.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.order.productName,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.order.status,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOrderDetail(
                    'Quantity',
                    '${widget.order.quantity} units',
                    Icons.inventory,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildOrderDetail(
                    'Preferred Date',
                    _formatDate(widget.order.preferredDeliveryDate),
                    Icons.calendar_today,
                    isDark,
                  ),
                ),
              ],
            ),
            if (widget.order.unitPrice != null) ...[
              const SizedBox(height: 12),
              _buildOrderDetail(
                'Unit Price',
                '\$${widget.order.unitPrice!.toStringAsFixed(2)}',
                Icons.attach_money,
                isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
                    Icon(icon, color: maroonDelivery, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Delivery Date
            Text(
              'Delivery Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDeliveryDate(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: maroonDelivery),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_deliveryDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: maroonDelivery),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Delivery Notes
            Text(
              'Delivery Notes (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes about the delivery...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _confirmDelivery,
        style: ElevatedButton.styleFrom(
          backgroundColor: maroonDelivery,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Confirm Delivery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _deliveryDate) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  Future<void> _confirmDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Record the delivery
      await DeliveryTrackingService.recordDelivery(
        orderId: widget.order.id,
        productName: widget.order.productName,
        quantity: widget.order.quantity,
        supplierName: widget.order.supplierName,
        supplierEmail: widget.order.supplierEmail,
        deliveryDate: _deliveryDate,
        unitPrice: widget.order.unitPrice,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Update stock levels automatically through delivery tracking service
      await DeliveryTrackingService.recordDelivery(
        orderId: widget.order.id,
        productName: widget.order.productName,
        quantity: widget.order.quantity,
        supplierName: widget.order.supplierName,
        supplierEmail: widget.order.supplierEmail,
        deliveryDate: _deliveryDate,
        unitPrice: widget.order.unitPrice,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Show success message
      if (mounted) {
        NotificationService.showNotification(
          context,
          'Delivery Confirmed',
          'Order #${widget.order.id} has been marked as delivered successfully.',
        );
        
        // Navigate back
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 