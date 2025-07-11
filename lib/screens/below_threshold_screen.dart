import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auto_reorder_service.dart';
import '../services/notification_service.dart';
import '../models/order.dart';

const _maroon = Color(0xFF800000);
const _lightCyan = Color(0xFFAFFFFF);

class BelowThresholdScreen extends StatefulWidget {
  final String vendorEmail;

  const BelowThresholdScreen({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<BelowThresholdScreen> createState() => _BelowThresholdScreenState();
}

class _BelowThresholdScreenState extends State<BelowThresholdScreen> {
  List<StockItem> belowThresholdItems = [];
  Map<String, int> manualOrderQuantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBelowThresholdItems();
  }

  Future<void> _loadBelowThresholdItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load stock items from Firestore
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .get();

      final allItems = stockSnapshot.docs.map((doc) {
        final data = doc.data();
        return StockItem(
          id: doc.id,
          productName: data['productName'] ?? '',
          currentStock: data['currentStock'] ?? 0,
          minimumStock: data['minimumStock'] ?? 0,
          maximumStock: data['maximumStock'] ?? 0,
          deliveryHistory: _parseDeliveryHistory(data['deliveryHistory'] ?? []),
          primarySupplier: data['primarySupplier'],
          primarySupplierEmail: data['primarySupplierEmail'],
          firstDeliveryDate: data['firstDeliveryDate'] != null 
              ? (data['firstDeliveryDate'] as Timestamp).toDate() 
              : null,
          lastDeliveryDate: data['lastDeliveryDate'] != null 
              ? (data['lastDeliveryDate'] as Timestamp).toDate() 
              : null,
          autoOrderEnabled: data['autoOrderEnabled'] ?? false,
          averageUnitPrice: data['averageUnitPrice']?.toDouble(),
        );
      }).toList();

      // Filter items below threshold
      final belowThreshold = allItems.where((item) {
        final percentage = item.maximumStock > 0 
            ? (item.currentStock / item.maximumStock * 100)
            : 0.0;
        final threshold = item.maximumStock > 0 
            ? (item.minimumStock / item.maximumStock * 100)
            : 20.0;
        return percentage <= threshold;
      }).toList();

      // Initialize manual order quantities
      for (final item in belowThreshold) {
        final lastOrderQuantity = item.deliveryHistory.isNotEmpty 
            ? item.deliveryHistory.last.quantity 
            : item.maximumStock;
        manualOrderQuantities[item.id] = lastOrderQuantity;
      }

      setState(() {
        belowThresholdItems = belowThreshold;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading below threshold items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<DeliveryRecord> _parseDeliveryHistory(List<dynamic> historyData) {
    return historyData.map((record) {
      return DeliveryRecord(
        id: record['id'] ?? '',
        orderId: record['orderId'] ?? '',
        productName: record['productName'] ?? '',
        quantity: record['quantity'] ?? 0,
        supplierName: record['supplierName'] ?? '',
        supplierEmail: record['supplierEmail'] ?? '',
        deliveryDate: record['deliveryDate'] != null 
            ? (record['deliveryDate'] as Timestamp).toDate() 
            : DateTime.now(),
        unitPrice: record['unitPrice']?.toDouble(),
        notes: record['notes'],
        status: record['status'] ?? 'Completed',
      );
    }).toList();
  }

  Future<void> _approveAutoOrder(StockItem item) async {
    try {
      if (item.primarySupplierEmail == null || item.primarySupplierEmail!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No supplier found for this product'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final lastOrderQuantity = item.deliveryHistory.isNotEmpty 
          ? item.deliveryHistory.last.quantity 
          : item.maximumStock;

      // Create auto-order
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'productName': item.productName,
        'quantity': lastOrderQuantity,
        'supplierName': item.primarySupplier ?? 'Unknown Supplier',
        'supplierEmail': item.primarySupplierEmail,
        'vendorEmail': widget.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'isAutoOrder': true,
        'autoOrderTriggeredAt': FieldValue.serverTimestamp(),
        'stockLevelAtTrigger': item.currentStock,
        'thresholdLevel': item.minimumStock,
        'notes': 'Auto-approved order due to low stock level',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications
      await NotificationService.notifySupplierOfAutoOrder(
        vendorEmail: widget.vendorEmail,
        supplierEmail: item.primarySupplierEmail!,
        orderId: orderRef.id,
        productName: item.productName,
        quantity: lastOrderQuantity,
        currentStock: item.currentStock,
        threshold: item.minimumStock,
      );

      await NotificationService.notifyVendorOfAutoOrder(
        vendorEmail: widget.vendorEmail,
        supplierEmail: item.primarySupplierEmail!,
        orderId: orderRef.id,
        productName: item.productName,
        quantity: lastOrderQuantity,
        currentStock: item.currentStock,
        threshold: item.minimumStock,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-order approved for ${item.productName}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBelowThresholdItems(); // Refresh the list
      }
    } catch (e) {
      print('Error approving auto-order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving auto-order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeManualOrder(StockItem item) async {
    try {
      final quantity = manualOrderQuantities[item.id] ?? item.maximumStock;
      
      if (item.primarySupplierEmail == null || item.primarySupplierEmail!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No supplier found for this product'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create manual order
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'productName': item.productName,
        'quantity': quantity,
        'supplierName': item.primarySupplier ?? 'Unknown Supplier',
        'supplierEmail': item.primarySupplierEmail,
        'vendorEmail': widget.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'isAutoOrder': false,
        'notes': 'Manual order placed due to low stock level',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to supplier
      await NotificationService.notifySupplierOfNewOrder(
        supplierEmail: item.primarySupplierEmail!,
        vendorEmail: widget.vendorEmail,
        orderId: orderRef.id,
        productName: item.productName,
        quantity: quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manual order placed for ${item.productName}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBelowThresholdItems(); // Refresh the list
      }
    } catch (e) {
      print('Error placing manual order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing manual order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Below Threshold'),
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadBelowThresholdItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : _lightCyan,
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : belowThresholdItems.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildBelowThresholdList(isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Stock Levels Good!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No products are currently below their threshold levels',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBelowThresholdList(bool isDark) {
    return Column(
      children: [
        // Header Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Low Stock Alert',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${belowThresholdItems.length} products below threshold',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Products List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: belowThresholdItems.length,
            itemBuilder: (context, index) {
              final item = belowThresholdItems[index];
              final percentage = item.maximumStock > 0 
                  ? (item.currentStock / item.maximumStock * 100)
                  : 0.0;
              final threshold = item.maximumStock > 0 
                  ? (item.minimumStock / item.maximumStock * 100)
                  : 20.0;
              final lastOrderQuantity = item.deliveryHistory.isNotEmpty 
                  ? item.deliveryHistory.last.quantity 
                  : item.maximumStock;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${item.currentStock} / ${item.maximumStock} units (${percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${threshold.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Stock Level Indicator
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${item.minimumStock} units needed',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Supplier Info
                      if (item.primarySupplier != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Supplier: ${item.primarySupplier}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveAutoOrder(item),
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: Text('Auto-Order\n$lastOrderQuantity units'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _maroon,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  onChanged: (value) {
                                    final quantity = int.tryParse(value) ?? lastOrderQuantity;
                                    manualOrderQuantities[item.id] = quantity;
                                  },
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _placeManualOrder(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text(
                                      'Order',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 