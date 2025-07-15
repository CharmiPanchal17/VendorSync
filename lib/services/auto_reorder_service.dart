import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../services/notification_service.dart';

class AutoReorderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Monitor stock levels and trigger auto-orders when thresholds are reached
  /// This can be called on every sale or as a background task
  static Future<void> monitorStockAndTriggerOrders() async {
    try {
      print('[AutoReorder] Starting stock monitoring...');
      
      // Get all stock items that have auto-order enabled
      final stockSnapshot = await _firestore
          .collection('stock_items')
          .where('autoOrderEnabled', isEqualTo: true)
          .get();

      for (final doc in stockSnapshot.docs) {
        final data = doc.data();
        await _checkAndTriggerOrder(doc.id, data);
      }
      
      print('[AutoReorder] Stock monitoring completed');
    } catch (e) {
      print('[AutoReorder] Error monitoring stock: $e');
    }
  }

  /// Check individual stock item and trigger order if needed
  static Future<void> _checkAndTriggerOrder(String stockId, Map<String, dynamic> data) async {
    try {
      final productName = data['productName'] as String? ?? '';
      final currentStock = data['currentStock'] as int? ?? 0;
      final minimumStock = data['minimumStock'] as int? ?? 0;
      final maximumStock = data['maximumStock'] as int? ?? 0;
      final vendorEmail = data['vendorEmail'] as String? ?? '';
      final supplierName = data['primarySupplier'] as String? ?? '';
      final supplierEmail = data['primarySupplierEmail'] as String? ?? '';
      final autoOrderQuantity = data['autoOrderQuantity'] as int? ?? maximumStock;

      // Calculate threshold (20% of initial stock or minimum stock, whichever is higher)
      final threshold = _calculateReorderThreshold(minimumStock, maximumStock);
      
      print('[AutoReorder] Checking $productName: current=$currentStock, threshold=$threshold');

      if (currentStock <= threshold) {
        print('[AutoReorder] Threshold reached for $productName. Triggering auto-order...');
        
        // Create automatic order
        await _createAutomaticOrder(
          productName: productName,
          quantity: autoOrderQuantity,
          supplierName: supplierName,
          supplierEmail: supplierEmail,
          vendorEmail: vendorEmail,
          stockId: stockId,
          currentStock: currentStock,
          threshold: threshold,
        );
      }
    } catch (e) {
      print('[AutoReorder] Error checking stock item $stockId: $e');
    }
  }

  /// Calculate reorder threshold (20% of initial stock or minimum stock)
  static int _calculateReorderThreshold(int minimumStock, int maximumStock) {
    final percentageThreshold = (maximumStock * 0.2).round(); // 20% threshold
    return percentageThreshold > minimumStock ? percentageThreshold : minimumStock;
  }

  /// Create automatic order to supplier
  static Future<void> _createAutomaticOrder({
    required String productName,
    required int quantity,
    required String supplierName,
    required String supplierEmail,
    required String vendorEmail,
    required String stockId,
    required int currentStock,
    required int threshold,
  }) async {
    try {
      // Check if there's already a pending auto-order for this product
      final existingOrderQuery = await _firestore
          .collection('orders')
          .where('productName', isEqualTo: productName)
          .where('supplierEmail', isEqualTo: supplierEmail)
          .where('status', whereIn: ['Pending', 'Pending Approval'])
          .where('isAutoOrder', isEqualTo: true)
          .get();

      if (existingOrderQuery.docs.isNotEmpty) {
        print('[AutoReorder] Auto-order already exists for $productName. Skipping...');
        return;
      }

      // Create the automatic order
      final orderRef = await _firestore.collection('orders').add({
        'productName': productName,
        'quantity': quantity,
        'supplierName': supplierName,
        'supplierEmail': supplierEmail,
        'vendorEmail': vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'isAutoOrder': true,
        'autoOrderTriggeredAt': FieldValue.serverTimestamp(),
        'stockLevelAtTrigger': currentStock,
        'thresholdLevel': threshold,
        'notes': 'Auto-generated order due to low stock level',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update stock item with auto-order information
      await _firestore.collection('stock_items').doc(stockId).update({
        'lastAutoOrderId': orderRef.id,
        'lastAutoOrderDate': FieldValue.serverTimestamp(),
        'lastAutoOrderStockLevel': currentStock,
      });

      // Send notification to supplier about auto-order
      await NotificationService.notifySupplierOfAutoOrder(
        vendorEmail: vendorEmail,
        supplierEmail: supplierEmail,
        orderId: orderRef.id,
        productName: productName,
        quantity: quantity,
        currentStock: currentStock,
        threshold: threshold,
      );

      // Send notification to vendor about auto-order
      await NotificationService.notifyVendorOfAutoOrder(
        vendorEmail: vendorEmail,
        supplierEmail: supplierEmail,
        orderId: orderRef.id,
        productName: productName,
        quantity: quantity,
        currentStock: currentStock,
        threshold: threshold,
      );

      print('[AutoReorder] Auto-order created successfully: ${orderRef.id}');
    } catch (e) {
      print('[AutoReorder] Error creating auto-order: $e');
    }
  }

  /// Enable auto-order for a stock item
  static Future<void> enableAutoOrder({
    required String stockId,
    required int autoOrderQuantity,
    required double reorderThreshold,
  }) async {
    try {
      await _firestore.collection('stock_items').doc(stockId).update({
        'autoOrderEnabled': true,
        'autoOrderQuantity': autoOrderQuantity,
        'reorderThreshold': reorderThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('[AutoReorder] Auto-order enabled for stock item: $stockId');
    } catch (e) {
      print('[AutoReorder] Error enabling auto-order: $e');
      rethrow;
    }
  }

  /// Disable auto-order for a stock item
  static Future<void> disableAutoOrder(String stockId) async {
    try {
      await _firestore.collection('stock_items').doc(stockId).update({
        'autoOrderEnabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('[AutoReorder] Auto-order disabled for stock item: $stockId');
    } catch (e) {
      print('[AutoReorder] Error disabling auto-order: $e');
      rethrow;
    }
  }

  /// Get auto-order statistics for a vendor
  static Future<Map<String, dynamic>> getAutoOrderStats(String vendorEmail) async {
    try {
      final autoOrdersQuery = await _firestore
          .collection('orders')
          .where('vendorEmail', isEqualTo: vendorEmail)
          .where('isAutoOrder', isEqualTo: true)
          .get();

      final autoOrders = autoOrdersQuery.docs;
      
      final totalAutoOrders = autoOrders.length;
      final pendingAutoOrders = autoOrders.where((doc) {
        final status = doc.data()['status'] as String? ?? '';
        return status == 'Pending' || status == 'Pending Approval';
      }).length;
      
      final completedAutoOrders = autoOrders.where((doc) {
        final status = doc.data()['status'] as String? ?? '';
        return status == 'Delivered';
      }).length;

      // Calculate total value of auto-orders
      double totalValue = 0;
      for (final doc in autoOrders) {
        final data = doc.data();
        final quantity = data['quantity'] as int? ?? 0;
        final unitPrice = data['unitPrice'] as double? ?? 0;
        totalValue += quantity * unitPrice;
      }

      return {
        'totalAutoOrders': totalAutoOrders,
        'pendingAutoOrders': pendingAutoOrders,
        'completedAutoOrders': completedAutoOrders,
        'totalValue': totalValue,
        'autoOrderPercentage': totalAutoOrders > 0 ? (autoOrders.length / totalAutoOrders * 100) : 0,
      };
    } catch (e) {
      print('[AutoReorder] Error getting auto-order stats: $e');
      return {
        'totalAutoOrders': 0,
        'pendingAutoOrders': 0,
        'completedAutoOrders': 0,
        'totalValue': 0,
        'autoOrderPercentage': 0,
      };
    }
  }

  /// Get low stock items that need attention
  static Future<List<Map<String, dynamic>>> getLowStockItems(String vendorEmail) async {
    try {
      final stockSnapshot = await _firestore
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: vendorEmail)
          .get();

      final lowStockItems = <Map<String, dynamic>>[];
      
      for (final doc in stockSnapshot.docs) {
        final data = doc.data();
        final currentStock = data['currentStock'] as int? ?? 0;
        final minimumStock = data['minimumStock'] as int? ?? 0;
        final maximumStock = data['maximumStock'] as int? ?? 0;
        final autoOrderEnabled = data['autoOrderEnabled'] as bool? ?? false;
        
        final threshold = _calculateReorderThreshold(minimumStock, maximumStock);
        
        if (currentStock <= threshold) {
          lowStockItems.add({
            'id': doc.id,
            'productName': data['productName'] ?? '',
            'currentStock': currentStock,
            'minimumStock': minimumStock,
            'maximumStock': maximumStock,
            'threshold': threshold,
            'autoOrderEnabled': autoOrderEnabled,
            'stockPercentage': maximumStock > 0 ? (currentStock / maximumStock) : 0,
            'needsAttention': currentStock <= minimumStock,
          });
        }
      }

      // Sort by urgency (lowest stock first)
      lowStockItems.sort((a, b) => a['currentStock'].compareTo(b['currentStock']));
      
      return lowStockItems;
    } catch (e) {
      print('[AutoReorder] Error getting low stock items: $e');
      return [];
    }
  }

  /// Set up real-time stock monitoring
  static Stream<QuerySnapshot> setupStockMonitoring(String vendorEmail) {
    return _firestore
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .where('autoOrderEnabled', isEqualTo: true)
        .snapshots();
  }

  /// Process stock monitoring stream
  static void processStockStream(QuerySnapshot snapshot) {
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _checkAndTriggerOrder(doc.id, data);
    }
  }
} 