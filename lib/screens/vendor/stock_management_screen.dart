import 'package:flutter/material.dart';  
import '../../models/order.dart';
import '../../mock_data/mock_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class StockManagementScreen extends StatefulWidget {
  final String vendorEmail;
  StockManagementScreen({Key? key, required this.vendorEmail}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  List<StockItem> stockItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final currentVendorEmail = widget.vendorEmail;
      print('DEBUG: Current vendor email: ' + (currentVendorEmail));

      // Try to load from Firestore first
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: currentVendorEmail)
          .get();

      print('DEBUG: Firestore stock_items found: \'${stockSnapshot.docs.length}\'');
      for (final doc in stockSnapshot.docs) {
        final data = doc.data();
        print('DEBUG: StockItem docId: ' + doc.id + ', vendorEmail: ' + (data['vendorEmail']?.toString() ?? 'NULL'));
      }

      if (stockSnapshot.docs.isNotEmpty) {
        // Load from Firestore
        final loadedStockItems = stockSnapshot.docs.map((doc) {
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
            vendorEmail: currentVendorEmail,
          );
        }).toList();

        setState(() {
          stockItems = loadedStockItems;
          isLoading = false;
        });
      } else {
        // If no stock data exists, create it from actual orders
        await _createStockFromOrders();
      }
    } catch (e) {
      print('Error loading stock data: $e');
      // Fallback to mock data
      setState(() {
        stockItems = List.from(mockStockItems);
        isLoading = false;
      });
    }
  }

  Future<void> _createStockFromOrders() async {
    try {
      final currentVendorEmail = widget.vendorEmail;
      if (currentVendorEmail == null) {
        throw Exception('No vendor is currently logged in.');
      }
      // Get all delivered orders from Firestore
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Delivered')
          .where('vendorEmail', isEqualTo: currentVendorEmail)
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        // No delivered orders, use mock data
        setState(() {
          stockItems = List.from(mockStockItems);
          isLoading = false;
        });
        await _saveStockDataToFirestore();
        return;
      }

      // Group orders by product name
      final Map<String, List<QueryDocumentSnapshot>> productGroups = {};
      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final productName = data['productName'] as String? ?? 'Unknown Product';
        productGroups.putIfAbsent(productName, () => []).add(doc);
      }

      // Create stock items from actual order data
      final List<StockItem> realStockItems = [];
      int stockId = 1;

      for (final entry in productGroups.entries) {
        final productName = entry.key;
        final orders = entry.value;
        
        // Calculate stock metrics from actual orders
        int totalDelivered = 0;
        double totalPrice = 0;
        int priceCount = 0;
        DateTime? firstDelivery;
        DateTime? lastDelivery;
        final List<DeliveryRecord> deliveryHistory = [];

        for (final orderDoc in orders) {
          final data = orderDoc.data() as Map<String, dynamic>;
          final quantity = data['quantity'] as int? ?? 0;
          final unitPrice = data['unitPrice'] as double?;
          final deliveryDate = data['approvedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?;
          
          totalDelivered += quantity;
          
          if (unitPrice != null) {
            totalPrice += unitPrice;
            priceCount++;
          }

          if (deliveryDate != null) {
            final date = deliveryDate.toDate();
            if (firstDelivery == null || date.isBefore(firstDelivery)) {
              firstDelivery = date;
            }
            if (lastDelivery == null || date.isAfter(lastDelivery)) {
              lastDelivery = date;
            }
          }

          // Create delivery record
          deliveryHistory.add(DeliveryRecord(
            id: 'del_${orderDoc.id}',
            orderId: orderDoc.id,
            productName: productName,
            quantity: quantity,
            supplierName: data['supplierName'] as String? ?? 'Unknown Supplier',
            supplierEmail: data['supplierEmail'] as String? ?? 'unknown@example.com',
            deliveryDate: deliveryDate?.toDate() ?? DateTime.now(),
            unitPrice: unitPrice,
            notes: 'Delivered from order',
            status: 'Completed',
            vendorEmail: currentVendorEmail,
          ));
        }

        // Calculate current stock (assuming some has been sold/used)
        final currentStock = (totalDelivered * 0.7).round(); // Assume 70% of delivered is still in stock
        final minimumStock = (totalDelivered * 0.1).round(); // 10% of total delivered as minimum
        final averageUnitPrice = priceCount > 0 ? totalPrice / priceCount : null;

        // Use consistent document ID: productName_vendorEmail
        final stockDocId = '${productName}_$currentVendorEmail';

        realStockItems.add(StockItem(
          id: stockDocId,
          productName: productName,
          currentStock: currentStock,
          minimumStock: minimumStock,
          maximumStock: totalDelivered, // Total delivered as maximum capacity
          deliveryHistory: deliveryHistory,
          primarySupplier: (orders.first.data() as Map<String, dynamic>)['supplierName'] as String? ?? 'Unknown Supplier',
          primarySupplierEmail: (orders.first.data() as Map<String, dynamic>)['supplierEmail'] as String? ?? 'unknown@example.com',
          firstDeliveryDate: firstDelivery,
          lastDeliveryDate: lastDelivery,
          autoOrderEnabled: false,
          averageUnitPrice: averageUnitPrice,
          vendorEmail: currentVendorEmail,
        ));

        // stockId++; // No longer needed
      }

      setState(() {
        stockItems = realStockItems;
        isLoading = false;
      });

      // Save the real stock data to Firestore
      await _saveStockDataToFirestore();

    } catch (e) {
      print('Error creating stock from orders: $e');
      // Fallback to mock data
      setState(() {
        stockItems = List.from(mockStockItems);
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
        vendorEmail: 'CURRENT_VENDOR_EMAIL',
      );
    }).toList();
  }

  Future<void> _saveStockDataToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final stockItem in stockItems) {
        final docRef = FirebaseFirestore.instance
            .collection('stock_items')
            .doc(stockItem.id);
        
        batch.set(docRef, {
          'productName': stockItem.productName,
          'currentStock': stockItem.currentStock,
          'minimumStock': stockItem.minimumStock,
          'maximumStock': stockItem.maximumStock,
          'deliveryHistory': stockItem.deliveryHistory.map((record) => {
            'id': record.id,
            'orderId': record.orderId,
            'productName': record.productName,
            'quantity': record.quantity,
            'supplierName': record.supplierName,
            'supplierEmail': record.supplierEmail,
            'deliveryDate': Timestamp.fromDate(record.deliveryDate),
            'unitPrice': record.unitPrice,
            'notes': record.notes,
            'status': record.status,
          }).toList(),
          'primarySupplier': stockItem.primarySupplier,
          'primarySupplierEmail': stockItem.primarySupplierEmail,
          'firstDeliveryDate': stockItem.firstDeliveryDate != null 
              ? Timestamp.fromDate(stockItem.firstDeliveryDate!) 
              : null,
          'lastDeliveryDate': stockItem.lastDeliveryDate != null 
              ? Timestamp.fromDate(stockItem.lastDeliveryDate!) 
              : null,
          'autoOrderEnabled': stockItem.autoOrderEnabled,
          'averageUnitPrice': stockItem.averageUnitPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('Stock data saved to Firestore successfully');
    } catch (e) {
      print('Error saving stock data to Firestore: $e');
    }
  }

  Future<void> _updateStockItem(int index, StockItem updatedStockItem) async {
    setState(() {
      stockItems[index] = updatedStockItem;
    });
    
    // Save to Firestore
    await _saveStockDataToFirestore();

    // --- SALES RECORDING LOGIC ---
    // If stock was reduced (i.e., a sale/purchase), record it in sales_history
    final oldStock = stockItems[index].currentStock;
    final newStock = updatedStockItem.currentStock;
    if (newStock < oldStock) {
      final quantitySold = oldStock - newStock;
      print('DEBUG: Attempting to write sales record for ${updatedStockItem.productName}, qty: $quantitySold');
      try {
        await FirebaseFirestore.instance.collection('sales_history').add({
          'productName': updatedStockItem.productName,
          'vendorEmail': updatedStockItem.vendorEmail,
          'quantity': quantitySold,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('DEBUG: Sales record written for ${updatedStockItem.productName}, qty: $quantitySold');
      } catch (e) {
        print('ERROR: Failed to write sales record: $e');
      }
    }

    // --- AUTO-ORDER LOGIC ---
    // Fetch product inventory settings for this product and vendor
    final inventoryQuery = await FirebaseFirestore.instance
        .collection('product_inventory')
        .where('productName', isEqualTo: updatedStockItem.productName)
        .where('vendorEmail', isEqualTo: updatedStockItem.vendorEmail)
        .limit(1)
        .get();
    if (inventoryQuery.docs.isEmpty) return;
    final inventory = inventoryQuery.docs.first;
    final data = inventory.data();
    final bool autoOrderEnabled = data['autoOrderEnabled'] ?? false;
    final int lowStockThreshold = data['lowStockThreshold'] ?? 0;
    final int autoOrderQuantity = data['autoOrderQuantity'] ?? 0;
    final String? supplierName = data['supplierName'];
    final String? supplierEmail = data['supplierEmail'];
    final bool autoOrderPending = data['autoOrderPending'] ?? false;

    // Only trigger if enabled, not already pending, and threshold reached
    if (autoOrderEnabled && !autoOrderPending && updatedStockItem.currentStock <= lowStockThreshold && autoOrderQuantity > 0 && supplierEmail != null && supplierName != null) {
      // Create a new order
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'productName': updatedStockItem.productName,
        'quantity': autoOrderQuantity,
        'supplierName': supplierName,
        'supplierEmail': supplierEmail,
        'vendorEmail': updatedStockItem.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': DateTime.now().add(const Duration(days: 7)),
        'autoOrderEnabled': true,
        'autoOrderThreshold': lowStockThreshold,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isAutoOrder': true,
      });
      // Mark auto-order as pending to prevent duplicates
      await inventory.reference.update({'autoOrderPending': true, 'lastOrderId': orderRef.id});
      // Notify supplier
      await NotificationService.notifySupplierOfNewOrder(
        vendorEmail: updatedStockItem.vendorEmail,
        supplierEmail: supplierEmail,
        orderId: orderRef.id,
        productName: updatedStockItem.productName,
        quantity: autoOrderQuantity,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-order placed for ${updatedStockItem.productName} (${autoOrderQuantity} units). Supplier notified.'),
            backgroundColor: Colors.green,
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
        title: const Text('Stock Management'),
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
                  : [maroon, maroon.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(maroon),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stockItems.length,
                itemBuilder: (context, index) {
                  final stockItem = stockItems[index];
                  return _buildStockCard(context, stockItem, isDark, index);
                },
              ),
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, StockItem stockItem, bool isDark, int index) {
    return Card(
      color: stockItem.isLowStock 
          ? Colors.red.shade50 
          : (isDark ? Colors.white10 : Colors.white),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: stockItem.isLowStock 
              ? maroon.withOpacity(0.2) 
              : Colors.grey.shade200,
          child: Icon(
            Icons.inventory, 
            color: stockItem.isLowStock ? maroon : Colors.grey
          ),
        ),
        title: Text(
          stockItem.productName, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock: 	${stockItem.currentStock} / ${stockItem.maximumStock}'),
            if (stockItem.isLowStock)
              Text(
                'Low Stock',
                style: TextStyle(
                  color: maroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stockItem.autoOrderEnabled)
              Icon(Icons.auto_awesome, color: maroon, size: 20),
            const SizedBox(width: 8),
            Icon(Icons.expand_more, color: maroon),
          ],
        ),
        children: [
          _buildStockDetails(context, stockItem, isDark, index),
        ],
      ),
    );
  }

  Widget _buildStockDetails(BuildContext context, StockItem stockItem, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Overview
          _buildStockOverview(stockItem, isDark),
          const SizedBox(height: 16),
          
          // Supplier Information
          if (stockItem.primarySupplier != null)
            _buildSupplierInfo(stockItem, isDark),
          
          const SizedBox(height: 16),
          
          // Delivery History
          _buildDeliveryHistory(stockItem, isDark),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          _buildActionButtons(context, stockItem, isDark, index),
        ],
      ),
    );
  }

  Widget _buildStockOverview(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: maroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Current Stock',
                  '${stockItem.currentStock}',
                  Icons.inventory,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Min Stock',
                  '${stockItem.minimumStock}',
                  Icons.warning,
                  isDark,
                ),
              ),
                                            Expanded(
                                child: _buildMetricItem(
                                  'Total Stock',
                                  '${stockItem.maximumStock}',
                                  Icons.storage,
                                  isDark,
                                ),
                              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stockItem.stockPercentage,
            backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStockProgressColor(stockItem, isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(stockItem.stockPercentage * 100).toStringAsFixed(1)}% of total capacity',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Supplier',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Icon(Icons.business, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockItem.primarySupplier!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      stockItem.primarySupplierEmail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (stockItem.averageUnitPrice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Avg. Unit Price: \$${stockItem.averageUnitPrice!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryHistory(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${stockItem.totalDeliveries} deliveries',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stockItem.firstDeliveryDate != null) ...[
            Text(
              'First Delivery: ${_formatDate(stockItem.firstDeliveryDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (stockItem.lastDeliveryDate != null) ...[
            Text(
              'Last Delivery: ${_formatDate(stockItem.lastDeliveryDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Total Delivered: ${stockItem.totalDelivered} units',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (stockItem.deliveryHistory.isNotEmpty) ...[
            Text(
              'Recent Deliveries:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...stockItem.deliveryHistory
                .take(3)
                .map((record) => _buildDeliveryRecord(record, isDark))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryRecord(DeliveryRecord record, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.quantity} units from ${record.supplierName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(record.deliveryDate),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (record.unitPrice != null)
            Text(
              '\$${record.unitPrice!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, StockItem stockItem, bool isDark, int index) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showEditStockDialog(context, stockItem, index);
            },
            icon: Icon(Icons.edit, size: 16),
            label: const Text('Update Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditStockDialog(BuildContext context, StockItem stockItem, int index) {
    final controller = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Enter number of goods purchased'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Quantity', errorText: errorText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final qty = int.tryParse(controller.text) ?? 0;
                if (qty <= 0) {
                  setState(() {
                    errorText = 'Please enter a positive quantity.';
                  });
                  return;
                }
                if (qty > stockItem.currentStock) {
                  setState(() {
                    errorText = 'Cannot purchase more than current stock.';
                  });
                  return;
                }
                final updatedStockItem = StockItem(
                  id: stockItem.id,
                  productName: stockItem.productName,
                  currentStock: stockItem.currentStock - qty,
                  minimumStock: stockItem.minimumStock,
                  maximumStock: stockItem.maximumStock,
                  deliveryHistory: stockItem.deliveryHistory,
                  primarySupplier: stockItem.primarySupplier,
                  primarySupplierEmail: stockItem.primarySupplierEmail,
                  firstDeliveryDate: stockItem.firstDeliveryDate,
                  lastDeliveryDate: stockItem.lastDeliveryDate,
                  autoOrderEnabled: stockItem.autoOrderEnabled,
                  averageUnitPrice: stockItem.averageUnitPrice,
                  vendorEmail: stockItem.vendorEmail,
                );
                await _updateStockItem(index, updatedStockItem);
                Navigator.pop(context);
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: maroon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStockProgressColor(StockItem stockItem, bool isDark) {
    // Calculate stock level relative to minimum stock
    final stockToMinRatio = stockItem.currentStock / stockItem.minimumStock;
    
    if (stockItem.isLowStock || stockToMinRatio <= 1.0) {
      return maroon; // Red for low stock (at or below minimum)
    } else if (stockToMinRatio <= 1.5) {
      return Colors.orange; // Orange for approaching threshold (1-1.5x minimum)
    } else {
      return Colors.green; // Green for good stock (above 1.5x minimum)
    }
  }
} 