import 'package:flutter/material.dart';  
import '../../models/order.dart';
import '../../mock_data/mock_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;


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
  List<Map<String, dynamic>> thresholdAnalysis = [];

  @override
  void initState() {
    super.initState();
    _loadStockData();
    _loadThresholdAnalysis();
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
            thresholdLevel: data['thresholdLevel'] ?? 0,
            thresholdNotificationsEnabled: data['thresholdNotificationsEnabled'] ?? true,
            lastThresholdAlert: data['lastThresholdAlert'] != null 
                ? (data['lastThresholdAlert'] as Timestamp).toDate() 
                : null,
            suggestedOrderQuantity: data['suggestedOrderQuantity'] ?? 0,
          );
        }).toList();

        setState(() {
          stockItems = _sortStockItems(loadedStockItems);
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
          stockItems = _sortStockItems(List.from(mockStockItems));
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
        stockItems = _sortStockItems(realStockItems);
        isLoading = false;
      });

      // Save the real stock data to Firestore
      await _saveStockDataToFirestore();

    } catch (e) {
      print('Error creating stock from orders: $e');
      // Fallback to mock data
      setState(() {
        stockItems = _sortStockItems(List.from(mockStockItems));
        isLoading = false;
      });
    }
  }

  Future<void> _loadThresholdAnalysis() async {
    try {
      final analysis = await SalesService.getThresholdAndAutoOrderAnalysis(vendorEmail: widget.vendorEmail);
      setState(() {
        thresholdAnalysis = analysis;
      });
    } catch (e) {
      // Optionally handle error
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
    final oldStock = stockItems[index].currentStock; // capture BEFORE setState
    setState(() {
      stockItems[index] = updatedStockItem;
      // Re-sort the list after updating to maintain threshold items first
      stockItems = _sortStockItems(List.from(stockItems));
    });
    final newStock = updatedStockItem.currentStock;
    final quantitySold = oldStock - newStock;
    print('DEBUG: oldStock: ' + oldStock.toString() + ', newStock: ' + newStock.toString() + ', quantitySold: ' + quantitySold.toString());
    if (newStock < oldStock) {
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
    await _saveStockDataToFirestore();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _showUploadDialog(context),
            tooltip: 'Upload Stock Data',
          ),
        ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await _loadStockData();
              await _loadThresholdAnalysis();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stock data refreshed.'), backgroundColor: maroon),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Initial Stock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => InitialStockUploadScreen(vendorEmail: widget.vendorEmail),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics),
                        label: const Text('Upload Sales Data for Analysis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SalesDataUploadScreen(vendorEmail: widget.vendorEmail),
                          ));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildStockItemWithAnalysis(stockItem, isDark),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemWithAnalysis(StockItem stockItem, bool isDark) {
    final analysis = thresholdAnalysis.firstWhere(
      (a) => a['productName'] == stockItem.productName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    Color getPriorityColor(String? priority) {
      switch (priority) {
        case 'High':
          return Colors.red;
        case 'Medium':
          return Colors.orange;
        case 'Low':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: analysis['priority'] == 'High'
              ? Colors.red.withOpacity(0.3)
              : analysis['priority'] == 'Medium'
                  ? Colors.orange.withOpacity(0.3)
                  : analysis['priority'] == 'Low'
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stockItem.productName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: isDark ? Colors.white : Colors.black87)),
              ),
              if (analysis.isNotEmpty)
                Tooltip(
                  message: 'Auto-Order Priority is based on sales velocity and stock status. High means reorder is urgent.',
                  child: Chip(
                    label: Text(
                      analysis['priority'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: getPriorityColor(analysis['priority']),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Current Stock: ${stockItem.currentStock}', style: const TextStyle(fontSize: 16)),
          if (analysis.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.flag, color: maroon, size: 20),
                const SizedBox(width: 6),
                Text('Recommended Threshold: ${analysis['recommendedThreshold']}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.speed, color: maroon, size: 20),
                const SizedBox(width: 6),
                Text('Sales Velocity: ${analysis['salesVelocity'].toStringAsFixed(2)} units/week', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            if (analysis['priority'] == 'High')
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Create Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  // Show supplier selection dialog before placing order
                  final supplier = await showDialog<Map<String, String>>(
                    context: context,
                    builder: (context) => _SupplierSelectDialog(
                      currentSupplier: stockItem.primarySupplier,
                      currentSupplierEmail: stockItem.primarySupplierEmail,
                    ),
                  );
                  if (supplier == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a supplier before placing an order.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  await SalesService.placeAutomaticOrder(
                    productName: stockItem.productName,
                    quantity: stockItem.minimumStock,
                    supplierName: supplier['name'],
                    supplierEmail: supplier['email'],
                    vendorEmail: 'vendor@example.com', // TODO: Replace with actual vendor email
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order created for ${stockItem.productName} with supplier ${supplier['name']}'),
                        backgroundColor: maroon,
                      ),
                    );
                  }
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, StockItem stockItem, bool isDark, int index) {
    final stockStatus = _getStockStatus(stockItem);
    final statusColor = _getStatusColor(stockStatus);
    final statusIcon = _getStatusIcon(stockStatus);
    final isAtThreshold = _isAtThreshold(stockItem);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAtThreshold ? Border.all(
          color: Colors.red,
          width: 2,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: isAtThreshold 
                ? Colors.red.withOpacity(0.3)
                : (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1)),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.2),
                statusColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
          stockItem.productName, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isAtThreshold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
          children: [
                        Icon(Icons.warning, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
              Text(
                          'THRESHOLD',
                style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
          children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    stockStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            const SizedBox(width: 8),
                if (stockItem.autoOrderEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: maroon.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: maroon.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: maroon, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          'Auto',
                          style: TextStyle(
                            color: maroon,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: maroon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.expand_more,
            color: maroon,
            size: 20,
          ),
        ),
        children: [
          _buildStockDetails(context, stockItem, isDark, index),
        ],
      ),
    );
  }



  String _getStockStatus(StockItem stockItem) {
    if (stockItem.currentStock <= (stockItem.minimumStock * 0.5)) {
      return 'Critical';
    } else if (stockItem.currentStock <= stockItem.minimumStock) {
      return 'Low';
    } else if (stockItem.currentStock <= (stockItem.minimumStock * 1.2)) {
      return 'Warning';
    } else {
      return 'Good';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical':
        return maroon;
      case 'Low':
        return maroon.withOpacity(0.8);
      case 'Warning':
        return maroon.withOpacity(0.6);
      case 'Good':
        return maroon.withOpacity(0.4);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Critical':
        return Icons.warning;
      case 'Low':
        return Icons.warning_amber;
      case 'Warning':
        return Icons.info;
      case 'Good':
        return Icons.check_circle;
      default:
        return Icons.inventory;
    }
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
    final stockStatus = _getStockStatus(stockItem);
    final statusColor = _getStatusColor(stockStatus);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.analytics,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
          Text(
            'Stock Overview',
            style: TextStyle(
                  fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stock Level Indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${(stockItem.stockPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStockProgressColor(stockItem, isDark),
                                ),
                              ),
            ],
          ),
          const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.6 * stockItem.stockPercentage,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_getStockProgressColor(stockItem, isDark), _getStockProgressColor(stockItem, isDark).withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
          Text(
                      '${stockItem.currentStock} units',
            style: TextStyle(
              fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                    Text(
                      '${stockItem.maximumStock} units',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          

        ],
      ),
    );
  }

  Widget _buildEnhancedMetricItem(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            maroon.withOpacity(0.1),
            maroon.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: maroon.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business,
                  color: maroon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Primary Supplier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Supplier Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        maroon.withOpacity(0.2),
                        maroon.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: maroon,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockItem.primarySupplier!,
                        style: TextStyle(
                        fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                    Text(
                      stockItem.primarySupplierEmail!,
                      style: TextStyle(
                        fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                          ),
                        ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
          
          if (stockItem.averageUnitPrice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: maroon.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: maroon,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
            Text(
                    'Average Unit Price',
              style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${stockItem.averageUnitPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: maroon,
                    ),
                  ),
                ],
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
        color: maroon.withOpacity(0.1),
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
                ,
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
            color: maroon,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            maroon.withOpacity(0.1),
            maroon.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: maroon.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.settings,
                  color: maroon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              // Call the auto-order logic for this stock item
              final productName = stockItem.productName;
              final quantity = stockItem.minimumStock; // or any test quantity
              final supplierName = stockItem.primarySupplier;
              final supplierEmail = stockItem.primarySupplierEmail;
              final vendorEmail = 'vendor@example.com'; // TODO: Replace with actual vendor email from context or user session
              await SalesService.placeAutomaticOrder(
                productName: productName,
                quantity: quantity,
                supplierName: supplierName,
                supplierEmail: supplierEmail,
                vendorEmail: vendorEmail,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Auto-order triggered for $productName')),
                );
              }
            },
            child: Text('Test Auto-Order'),
          ),
        ),
      ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 2,
                child: _buildActionButton(
                  'Update Stock',
                  Icons.edit,
                  maroon,
                  () => _showEditStockDialog(context, stockItem, index),
                  isDark,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 2,
                child: _buildActionButton(
                  'View Analytics',
                  Icons.analytics,
                  maroon.withOpacity(0.8),
                  () => _navigateToAnalytics(stockItem),
                  isDark,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 2,
                child: _buildActionButton(
                  'Set Threshold',
                  Icons.warning,
                  maroon.withOpacity(0.6),
                  () => _navigateToThresholdManagement(stockItem),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed, bool isDark) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAnalytics(StockItem stockItem) {
    Navigator.of(context).pushNamed(
      '/vendor-product-analytics',
      arguments: stockItem.productName,
    );
  }

  void _navigateToThresholdManagement(StockItem stockItem) {
    Navigator.of(context).pushNamed(
      '/vendor-threshold-management',
      arguments: widget.vendorEmail,
    );
  }

  void _navigateToOrder(StockItem stockItem) {
    Navigator.of(context).pushNamed(
      '/vendor-quick-order',
      arguments: {
        'productName': stockItem.productName,
        'suggestedQuantity': stockItem.calculateSuggestedOrderQuantity(),
        'supplierEmail': stockItem.primarySupplierEmail,
        'supplierName': stockItem.primarySupplier,
        'vendorEmail': widget.vendorEmail,
      },
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
pload Spreadsheet'),
          ),
        ],
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$qty units of ${stockItem.productName} have been sold.'),
                      backgroundColor: maroon, // Use maroon color for confirmation
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRealTimeSalesOption(BuildContext context) {
    // Navigate to real-time sales screen
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => RealTimeSalesScreen(
        vendorEmail: widget.vendorEmail,
      ),
    ));
  }

  void _showSpreadsheetUploadOption(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SpreadsheetUploadScreen(
        vendorEmail: widget.vendorEmail,
      ),
    ));
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
      return Colors.red; // Red for critical low stock (at or below minimum)
    } else if (stockToMinRatio <= 1.2) {
      return Colors.orange; // Orange for low stock (approaching threshold)
    } else if (stockToMinRatio <= 1.5) {
      return Colors.yellow; // Yellow for warning (close to threshold)
    } else {
      return Colors.green; // Green for good stock (well above threshold)
    }
  }

  List<StockItem> _sortStockItems(List<StockItem> items) {
    // Sort items: threshold items first, then by stock level
    items.sort((a, b) {
      final aIsAtThreshold = a.currentStock <= a.minimumStock;
      final bIsAtThreshold = b.currentStock <= b.minimumStock;
      
      // If one is at threshold and the other isn't, threshold item comes first
      if (aIsAtThreshold && !bIsAtThreshold) return -1;
      if (!aIsAtThreshold && bIsAtThreshold) return 1;
      
      // If both are at threshold or both are not, sort by stock level (lowest first)
      final aRatio = a.currentStock / a.minimumStock;
      final bRatio = b.currentStock / b.minimumStock;
      
      return aRatio.compareTo(bRatio);
    });
    
    // Debug: Print the sorted order
    print('DEBUG: Sorted stock items:');
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isAtThreshold = item.currentStock <= item.minimumStock;
      print('  ${i + 1}. ${item.productName} - Current: ${item.currentStock}, Min: ${item.minimumStock}, At Threshold: $isAtThreshold');
    }
    
    return items;
  }

  bool _isAtThreshold(StockItem stockItem) {
    return stockItem.currentStock <= stockItem.minimumStock;
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload, color: maroon),
            const SizedBox(width: 8),
            const Text('Upload Stock Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how you want to upload stock data:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildUploadOption(
              context,
              'CSV File',
              'Upload stock data from a CSV file',
              Icons.table_chart,
              () => _uploadFromCSV(context),
            ),
            const SizedBox(height: 12),
            _buildUploadOption(
              context,
              'Spreadsheet',
              'Add stock items via spreadsheet',
              Icons.table_view,
              () => _uploadFromCSV(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption(BuildContext context, String title, String description, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: maroon, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _uploadFromCSV(BuildContext context) async {
    Navigator.pop(context);
    try {
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'spreadsheet',
        extensions: ['csv', 'xlsx'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        List<List<dynamic>>? rows;
        if (file.name.toLowerCase().endsWith('.csv')) {
          final csvString = await file.readAsString();
          rows = const CsvToListConverter().convert(csvString, eol: '\n');
        } else if (file.name.toLowerCase().endsWith('.xlsx')) {
          final bytes = await file.readAsBytes();
          final excel = ex.Excel.decodeBytes(bytes);
          final sheet = excel.tables.values.first;
          rows = sheet.rows;
        }
        if (rows != null) {
          // Expecting header: Product Name,Current Stock,Minimum Stock,Maximum Stock,Supplier Name,Supplier Email
          int added = 0;
          for (int i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length < 6) continue;
            final productName = row[0]?.toString() ?? '';
            final currentStock = int.tryParse(row[1]?.toString() ?? '') ?? 0;
            final minimumStock = int.tryParse(row[2]?.toString() ?? '') ?? 0;
            final maximumStock = int.tryParse(row[3]?.toString() ?? '') ?? 0;
            final supplierName = row[4]?.toString() ?? '';
            final supplierEmail = row[5]?.toString() ?? '';
            if (productName.isEmpty) continue;
            final stockDocId = '${productName}_${widget.vendorEmail}';
            await FirebaseFirestore.instance.collection('stock_items').doc(stockDocId).set({
              'productName': productName,
              'currentStock': currentStock,
              'minimumStock': minimumStock,
              'maximumStock': maximumStock,
              'primarySupplier': supplierName,
              'primarySupplierEmail': supplierEmail,
              'vendorEmail': widget.vendorEmail,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            added++;
          }
          await _loadStockData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded $added stock items.'),
              backgroundColor: maroon,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No valid data found in file.'),
              backgroundColor: maroon,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No file selected.'),
            backgroundColor: maroon,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showManualEntryDialog(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Spreadsheet functionality coming soon!'),
        backgroundColor: maroon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }



  void _showAddStockDialog(BuildContext context) {
    final productNameController = TextEditingController();
    final currentStockController = TextEditingController();
    final minimumStockController = TextEditingController();
    final maximumStockController = TextEditingController();
    final supplierController = TextEditingController();
    final supplierEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add, color: maroon),
            const SizedBox(width: 8),
            const Text('Add New Stock Item'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minimumStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maximumStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Supplier Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroon,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final productName = productNameController.text.trim();
              final currentStock = int.tryParse(currentStockController.text) ?? 0;
              final minimumStock = int.tryParse(minimumStockController.text) ?? 0;
              final maximumStock = int.tryParse(maximumStockController.text) ?? 0;
              final supplierName = supplierController.text.trim();
              final supplierEmail = supplierEmailController.text.trim();

              if (productName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a product name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newStockItem = StockItem(
                id: '${productName}_${widget.vendorEmail}',
                productName: productName,
                currentStock: currentStock,
                minimumStock: minimumStock,
                maximumStock: maximumStock,
                deliveryHistory: [],
                primarySupplier: supplierName.isNotEmpty ? supplierName : null,
                primarySupplierEmail: supplierEmail.isNotEmpty ? supplierEmail : null,
                firstDeliveryDate: null,
                lastDeliveryDate: null,
                autoOrderEnabled: false,
                averageUnitPrice: null,
                vendorEmail: widget.vendorEmail,
              );

              setState(() {
                stockItems.add(newStockItem);
                stockItems = _sortStockItems(List.from(stockItems));
              });

              await _saveStockDataToFirestore();
              Navigator.pop(context);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added new stock item: $productName'),
                    backgroundColor: maroon,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
} 

class _SupplierSelectDialog extends StatefulWidget {
  final String? currentSupplier;
  final String? currentSupplierEmail;
  const _SupplierSelectDialog({this.currentSupplier, this.currentSupplierEmail});
  @override
  State<_SupplierSelectDialog> createState() => _SupplierSelectDialogState();
}

class _SupplierSelectDialogState extends State<_SupplierSelectDialog> {
  String? selectedSupplierName;
  String? selectedSupplierEmail;
  List<Map<String, String>> suppliers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    // Load suppliers from Firestore
    final snapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    setState(() {
      suppliers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': (data['name'] ?? 'Unknown').toString(),
          'email': (data['email'] ?? '').toString(),
        };
      }).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Supplier'),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: 300,
              child: DropdownButtonFormField<String>(
                value: selectedSupplierEmail,
                hint: const Text('Choose a supplier'),
                items: suppliers.map((s) => DropdownMenuItem<String>(
                  value: s['email'],
                  child: Text('${s['name']} (${s['email']})'),
                )).toList(),
                onChanged: (value) {
                  final supplier = suppliers.firstWhere((s) => s['email'] == value);
                  setState(() {
                    selectedSupplierName = supplier['name'];
                    selectedSupplierEmail = supplier['email'];
                  });
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: maroon),
          onPressed: selectedSupplierEmail == null
              ? null
              : () {
                  Navigator.of(context).pop({
                    'name': selectedSupplierName,
                    'email': selectedSupplierEmail,
                  });
                },
          child: const Text('Select'),
        ),
      ],
    );
  }
} 