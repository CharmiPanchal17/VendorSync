import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order.dart';
import '../../services/notification_service.dart';

const maroonOrders = Color(0xFF800000);
const lightCyanOrders = Color(0xFFAFFFFF);

class OrdersScreen extends StatefulWidget {
  final String vendorEmail;
  
  const OrdersScreen({super.key, required this.vendorEmail});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<StockItem> thresholdProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThresholdProducts();
  }

  Future<void> _loadThresholdProducts() async {
    try {
      setState(() { isLoading = true; });
      
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .get();

      if (stockSnapshot.docs.isNotEmpty) {
        print('Found ${stockSnapshot.docs.length} stock items for vendor: ${widget.vendorEmail}');
        
        final loadedStockItems = stockSnapshot.docs.map((doc) {
          final data = doc.data();
          final item = StockItem(
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
            vendorEmail: data['vendorEmail'] ?? '',
            thresholdLevel: data['thresholdLevel'] ?? 0,
            thresholdNotificationsEnabled: data['thresholdNotificationsEnabled'] ?? true,
            lastThresholdAlert: data['lastThresholdAlert'] != null 
                ? (data['lastThresholdAlert'] as Timestamp).toDate() 
                : null,
            suggestedOrderQuantity: data['suggestedOrderQuantity'] ?? 0,
          );
          
          print('Product: ${item.productName}');
          print('  Current Stock: ${item.currentStock}');
          print('  Minimum Stock: ${item.minimumStock}');
          print('  Threshold Level: ${item.thresholdLevel}');
          print('  Is at threshold: ${item.isAtThreshold}');
          print('  Is critical: ${item.isCriticalStock}');
          print('  Needs restock: ${item.needsRestock}');
          
          return item;
        }).toList();

        // Filter only products that have reached threshold
        final thresholdItems = loadedStockItems.where((item) => 
          item.isAtThreshold || item.isCriticalStock || item.needsRestock
        ).toList();

        print('Found ${thresholdItems.length} items that need ordering');

        setState(() {
          thresholdProducts = thresholdItems;
          isLoading = false;
        });
      } else {
        print('No stock items found for vendor: ${widget.vendorEmail}');
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print('Error loading threshold products: $e');
      setState(() { isLoading = false; });
    }
  }

  List<DeliveryRecord> _parseDeliveryHistory(List<dynamic> history) {
    return history.map((item) => DeliveryRecord(
      id: item['id'] ?? '',
      orderId: item['orderId'] ?? '',
      productName: item['productName'] ?? '',
      quantity: item['quantity'] ?? 0,
      supplierName: item['supplierName'] ?? '',
      supplierEmail: item['supplierEmail'] ?? '',
      deliveryDate: (item['deliveryDate'] as Timestamp).toDate(),
      unitPrice: item['unitPrice']?.toDouble(),
      notes: item['notes'],
      status: item['status'] ?? '',
      vendorEmail: widget.vendorEmail,
    )).toList();
  }

  Future<void> _addTestData() async {
    try {
      // Add a test product that will appear in orders
      await FirebaseFirestore.instance.collection('stock_items').add({
        'productName': 'Test Product - Low Stock',
        'currentStock': 20, // Low stock
        'minimumStock': 100,
        'maximumStock': 200,
        'thresholdLevel': 50, // Will trigger threshold
        'thresholdNotificationsEnabled': true,
        'vendorEmail': widget.vendorEmail,
        'primarySupplier': 'Test Supplier',
        'primarySupplierEmail': 'supplier@test.com',
        'averageUnitPrice': 25.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add another test product
      await FirebaseFirestore.instance.collection('stock_items').add({
        'productName': 'Test Product - Critical',
        'currentStock': 10, // Critical stock
        'minimumStock': 100,
        'maximumStock': 200,
        'thresholdLevel': 80,
        'thresholdNotificationsEnabled': true,
        'vendorEmail': widget.vendorEmail,
        'primarySupplier': 'Test Supplier 2',
        'primarySupplierEmail': 'supplier2@test.com',
        'averageUnitPrice': 30.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test data added! Refresh to see products.'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload the data
      await _loadThresholdProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _addTestData,
            tooltip: 'Add Test Data',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                  : [maroonOrders, maroonOrders.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyanOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : thresholdProducts.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: thresholdProducts.length,
                    itemBuilder: (context, index) {
                      final item = thresholdProducts[index];
                      return _buildOrderCard(item, isDark);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your products are well stocked!',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white38 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(StockItem item, bool isDark) {
    final thresholdStatus = item.thresholdStatus;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (thresholdStatus) {
      case ThresholdStatus.critical:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        statusText = 'Critical';
        break;
      case ThresholdStatus.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber;
        statusText = 'Low Stock';
        break;
      case ThresholdStatus.info:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        statusText = 'Running Low';
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Normal';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with product info and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Current Stock: ${item.currentStock}',
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: item.stockPercentage.clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.white24 : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(item.stockPercentage * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Threshold: ${item.thresholdLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Suggested Order Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggested Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '${item.calculateSuggestedOrderQuantity()} units',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow button to view details
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => _navigateToSuggestedOrderDetails(item),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToProductAnalytics(item.productName),
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Analytics'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: maroonOrders,
                      side: BorderSide(color: maroonOrders),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showOrderConfirmationDialog(item, isDark),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Confirm Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonOrders,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductAnalytics(String productName) {
    Navigator.of(context).pushNamed(
      '/vendor-product-analytics',
      arguments: productName,
    );
  }

  void _navigateToSuggestedOrderDetails(StockItem item) {
    Navigator.of(context).pushNamed(
      '/vendor-suggested-order-details',
      arguments: item,
    );
  }

  void _showOrderConfirmationDialog(StockItem item, bool isDark) {
    final quantityController = TextEditingController(
      text: item.calculateSuggestedOrderQuantity().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Confirm Order for ${item.productName}',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Supplier Information
            if (item.primarySupplier != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: maroonOrders,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supplier: ${item.primarySupplier}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (item.primarySupplierEmail != null)
                            Text(
                              item.primarySupplierEmail!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Current Stock: ${item.currentStock}\nThreshold Level: ${item.thresholdLevel}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Order Quantity',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: maroonOrders),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity > 0) {
                _placeOrder(item, quantity);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonOrders,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(StockItem item, int quantity) async {
    try {
      final orderData = {
        'productName': item.productName,
        'quantity': quantity,
        'supplierName': item.primarySupplier,
        'supplierEmail': item.primarySupplierEmail,
        'vendorEmail': widget.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'isAutoOrder': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final orderRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);

      // Create notification for supplier
      if (item.primarySupplierEmail != null) {
        await NotificationService.notifySupplierOfNewOrder(
          supplierEmail: item.primarySupplierEmail!,
          vendorEmail: widget.vendorEmail,
          orderId: orderRef.id,
          productName: item.productName,
          quantity: quantity,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully for ${item.productName}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload the list
      await _loadThresholdProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 