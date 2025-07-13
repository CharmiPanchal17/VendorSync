import 'package:flutter/material.dart';  
import '../../models/order.dart';
import '../../mock_data/mock_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'real_time_sales_screen.dart';
import '../../services/sales_service.dart';
import 'spreadsheet_upload_screen.dart';
import 'initial_stock_upload_screen.dart'; // Added import for InitialStockUploadScreen
import 'sales_data_upload_screen.dart'; // Added import for SalesDataUploadScreen

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class StockManagementScreen extends StatefulWidget {
  final String vendorEmail;
  const StockManagementScreen({super.key, required this.vendorEmail});

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

      // Try to load from Firestore first
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .get();

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
      // Get all delivered orders from Firestore
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Delivered')
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
          ));
        }

        // Calculate current stock (assuming some has been sold/used)
        final currentStock = (totalDelivered * 0.7).round(); // Assume 70% of delivered is still in stock
        final minimumStock = (totalDelivered * 0.1).round(); // 10% of total delivered as minimum
        final averageUnitPrice = priceCount > 0 ? totalPrice / priceCount : null;

        realStockItems.add(StockItem(
          id: 'stock_$stockId',
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
        ));

        stockId++;
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
    );
  }

  void _showEditStockDialog(BuildContext context, StockItem stockItem, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: const Text('How would you like to update the stock?'),
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
            onPressed: () {
              Navigator.pop(context);
              _showRealTimeSalesOption(context);
            },
            child: const Text('Real-time Sales'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroon,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showSpreadsheetUploadOption(context);
            },
            child: const Text('Upload Spreadsheet'),
          ),
        ],
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
      return maroon; // Red for low stock (at or below minimum)
    } else if (stockToMinRatio <= 1.5) {
      return Colors.orange; // Orange for approaching threshold (1-1.5x minimum)
    } else {
      return Colors.green; // Green for good stock (above 1.5x minimum)
    }
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