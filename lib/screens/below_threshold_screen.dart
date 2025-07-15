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
  Map<String, Map<String, String>> selectedSuppliers = {}; // {stockItemId: {name, email}}
  List<Map<String, String>> suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadBelowThresholdItems();
    _loadSuppliers();
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

  Future<void> _loadSuppliers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('suppliers').get();
      setState(() {
        suppliers = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': (data['name'] ?? '').toString(),
            'email': (data['email'] ?? '').toString(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  Future<void> _addSupplierDialog() async {
    String name = '';
    String email = '';
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                onChanged: (v) => name = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                onChanged: (v) => email = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await FirebaseFirestore.instance.collection('suppliers').add({'name': name, 'email': email});
                Navigator.pop(context, {'name': name ?? '', 'email': email ?? ''});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        suppliers.add(result);
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
      final supplier = selectedSuppliers[item.id];
      if (supplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier before placing an order.'),
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
        'supplierName': supplier['name'],
        'supplierEmail': supplier['email'],
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
        supplierEmail: supplier['email']!,
        orderId: orderRef.id,
        productName: item.productName,
        quantity: lastOrderQuantity,
        currentStock: item.currentStock,
        threshold: item.minimumStock,
      );

      await NotificationService.notifyVendorOfAutoOrder(
        vendorEmail: widget.vendorEmail,
        supplierEmail: supplier['email']!,
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
      final supplier = selectedSuppliers[item.id];
      if (supplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier before placing an order.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create manual order
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'productName': item.productName,
        'quantity': quantity,
        'supplierName': supplier['name'],
        'supplierEmail': supplier['email'],
        'vendorEmail': widget.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'isManualOrder': true,
        'manualOrderTriggeredAt': FieldValue.serverTimestamp(),
        'stockLevelAtTrigger': item.currentStock,
        'thresholdLevel': item.minimumStock,
        'notes': 'Manual order placed by vendor',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to supplier
      await NotificationService.notifySupplierOfNewOrder(
        supplierEmail: supplier['email']!,
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

  Future<Map<String, dynamic>> _fetchProductAnalytics(String productName) async {
    // Fetch sales records for this product and vendor
    final salesSnapshot = await FirebaseFirestore.instance
        .collection('sales_records')
        .where('vendorEmail', isEqualTo: widget.vendorEmail)
        .where('productName', isEqualTo: productName)
        .orderBy('soldAt', descending: true)
        .get();
    final now = DateTime.now();
    int totalSold = 0;
    int soldLast7 = 0;
    int soldLast30 = 0;
    DateTime? firstSale;
    DateTime? lastSale;
    for (final doc in salesSnapshot.docs) {
      final data = doc.data();
      final soldAt = data['soldAt'] is Timestamp ? (data['soldAt'] as Timestamp).toDate() : now;
      final qtyRaw = data['quantity'] ?? 0;
      final qty = qtyRaw is int ? qtyRaw : (qtyRaw is num ? qtyRaw.toInt() : 0);
      totalSold += qty;
      if (now.difference(soldAt).inDays <= 7) soldLast7 += qty;
      if (now.difference(soldAt).inDays <= 30) soldLast30 += qty;
      if (firstSale == null || soldAt.isBefore(firstSale)) firstSale = soldAt;
      if (lastSale == null || soldAt.isAfter(lastSale)) lastSale = soldAt;
    }
    final weeklyRate = soldLast7 / 1.0;
    final monthlyRate = soldLast30 / 4.0;
    final trend = weeklyRate > 10 ? 'Up' : weeklyRate == 0 ? 'No sales' : 'Steady';
    final duration = firstSale != null ? now.difference(firstSale).inDays : 0;
    final reorderSuggestion = weeklyRate > 0 ? (weeklyRate * 2).ceil() : 1;
    return {
      'totalSold': totalSold,
      'soldLast7': soldLast7,
      'soldLast30': soldLast30,
      'weeklyRate': weeklyRate,
      'monthlyRate': monthlyRate,
      'trend': trend,
      'duration': duration,
      'reorderSuggestion': reorderSuggestion,
      'firstSale': firstSale,
      'lastSale': lastSale,
    };
  }

  void _showProductReport(BuildContext context, StockItem item) async {
    final analytics = await _fetchProductAnalytics(item.productName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report: ${item.productName}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Metric')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    DataRow(cells: [DataCell(Text('Total Sold')), DataCell(Text('${analytics['totalSold']}'))]),
                    DataRow(cells: [DataCell(Text('Sold Last 7 Days')), DataCell(Text('${analytics['soldLast7']}'))]),
                    DataRow(cells: [DataCell(Text('Sold Last 30 Days')), DataCell(Text('${analytics['soldLast30']}'))]),
                    DataRow(cells: [DataCell(Text('Weekly Sales Rate')), DataCell(Text('${analytics['weeklyRate'].toStringAsFixed(2)}'))]),
                    DataRow(cells: [DataCell(Text('Monthly Sales Rate')), DataCell(Text('${analytics['monthlyRate'].toStringAsFixed(2)}'))]),
                    DataRow(cells: [DataCell(Text('Trend')), DataCell(Text('${analytics['trend']}'))]),
                    DataRow(cells: [DataCell(Text('Duration in Stock (days)')), DataCell(Text('${analytics['duration']}'))]),
                    DataRow(cells: [DataCell(Text('Suggested Reorder Qty')), DataCell(Text('${analytics['reorderSuggestion']}'))]),
                  ],
                ),
                const SizedBox(height: 16),
                if (analytics['firstSale'] != null && analytics['lastSale'] != null)
                  Text('Sales from: ${analytics['firstSale']} to ${analytics['lastSale']}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                      ElevatedButton.icon(
                        icon: Icon(Icons.analytics),
                        label: Text('View Product Report'),
                        onPressed: () => _showProductReport(context, item),
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

  Widget _buildSupplierDropdown(StockItem item) {
    final selected = selectedSuppliers[item.id];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Map<String, String>>(
            isExpanded: true,
            value: selected,
            hint: const Text('Select Supplier'),
            items: [
              ...suppliers.map((s) => DropdownMenuItem(
                value: s,
                child: Text('${s['name']} (${s['email']})'),
              )),
              DropdownMenuItem(
                value: null,
                child: GestureDetector(
                  onTap: _addSupplierDialog,
                  child: const Text('Add New Supplier'),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedSuppliers[item.id] = value;
                });
              }
            },
            validator: (v) => v == null ? 'Select supplier' : null,
          ),
        ),
      ],
    );
  }
} 