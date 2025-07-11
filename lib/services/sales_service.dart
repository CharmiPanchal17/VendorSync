import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sales.dart';
import '../models/order.dart';
import '../services/notification_service.dart'; // Added import for NotificationService
import '../services/auto_reorder_service.dart'; // Added import for AutoReorderService
import '../models/notification.dart';

class SalesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate unique invoice number
  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$timestamp';
  }

  // Create a new sales invoice
  static Future<SalesInvoice> createSalesInvoice({
    required List<SalesItem> items,
    required String vendorEmail,
    String? notes,
  }) async {
    try {
      final invoiceNumber = _generateInvoiceNumber();
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      final invoice = SalesInvoice(
        id: '',
        invoiceNumber: invoiceNumber,
        items: items,
        createdAt: DateTime.now(),
        totalAmount: totalAmount,
        vendorEmail: vendorEmail,
        notes: notes,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('sales_invoices').add(invoice.toMap());
      
      // Update stock levels for each item
      for (final item in items) {
        await _updateStockAfterSale(item.productName, item.quantity);
      }

      // Create sales records for analytics
      await _createSalesRecords(invoice, docRef.id);

      return SalesInvoice(
        id: docRef.id,
        invoiceNumber: invoice.invoiceNumber,
        items: invoice.items,
        createdAt: invoice.createdAt,
        totalAmount: invoice.totalAmount,
        vendorEmail: invoice.vendorEmail,
        notes: invoice.notes,
        status: invoice.status,
      );
    } catch (e) {
      throw Exception('Failed to create sales invoice: $e');
    }
  }

  // Update stock after a sale
  static Future<void> _updateStockAfterSale(String productName, int quantity) async {
    try {
      print('[StockUpdate] Attempting to update stock for "$productName" by $quantity');
      final stockQuery = await _firestore
          .collection('stock_items')
          .where('productName', isEqualTo: productName)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final data = stockDoc.data();
        final currentStock = data['currentStock'] as int;
        final minimumStock = data['minimumStock'] ?? 0;
        final maximumStock = data['maximumStock'] ?? 0;
        final vendorEmail = data['vendorEmail'] ?? '';
        final supplierEmail = data['primarySupplierEmail'] ?? '';
        final supplierName = data['primarySupplier'] ?? '';
        final newStock = currentStock - quantity;
        print('[StockUpdate] $productName: currentStock=$currentStock, quantity=$quantity, newStock=$newStock');

        if (newStock < 0) {
          print('[StockUpdate][ERROR] Insufficient stock for $productName.');
          throw Exception('Insufficient stock for $productName');
        }

        await stockDoc.reference.update({
          'currentStock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // --- Enhanced Auto-Reorder Logic ---
        // Use the new AutoReorderService for intelligent threshold checking
        await AutoReorderService.monitorStockAndTriggerOrders();
        
        // Also trigger immediate notification for critical stock levels
        final criticalThreshold = (maximumStock * 0.1).round(); // 10% critical threshold
        if (newStock <= criticalThreshold) {
          await NotificationService.sendStockThresholdNotification(
            vendorEmail: vendorEmail,
            productName: productName,
            currentStock: newStock,
            threshold: criticalThreshold,
            supplierName: supplierName,
            supplierEmail: supplierEmail,
            suggestedQuantity: maximumStock,
          );
        }
      } else {
        print('[StockUpdate][ERROR] No stock item found for "$productName".');
        // No stock item found for this product
        throw Exception('No stock item found for "$productName". Please check the product name in your stock list.');
      }
    } catch (e) {
      print('[StockUpdate][EXCEPTION] $e');
      throw Exception('Failed to update stock: $e');
    }
  }

  // Place an automatic order to the supplier when threshold is reached
  static Future<void> _placeAutomaticOrder({
    required String productName,
    required int quantity,
    required String? supplierName,
    required String? supplierEmail,
    required String? vendorEmail,
  }) async {
    try {
      print('[AutoOrder] Placing automatic order: $quantity x $productName to $supplierName <$supplierEmail> for vendor $vendorEmail');
      if (supplierEmail == null || supplierEmail.isEmpty || vendorEmail == null || vendorEmail.isEmpty) {
        print('[AutoOrder][ERROR] Supplier or vendor email missing, cannot place order.');
        return;
      }
      // Create order document in Firestore
      final orderData = {
        'productName': productName,
        'quantity': quantity,
        'supplierName': supplierName ?? '',
        'supplierEmail': supplierEmail ?? '',
        'vendorEmail': vendorEmail ?? '',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'autoOrder': true,
      };
      await _firestore.collection('orders').add(orderData);
      print('[AutoOrder] Order document created in Firestore.');
      // Send notification to vendor
      await NotificationService.createNotification(
        recipientEmail: vendorEmail,
        title: 'Automatic Order Placed',
        message: 'An automatic order for $quantity x $productName has been placed to $supplierName.',
        type: NotificationType.orderPlaced,
      );
      print('[AutoOrder] Notification sent to vendor.');
    } catch (e) {
      print('[AutoOrder][EXCEPTION] $e');
    }
  }

  static Future<void> placeAutomaticOrder({
    required String productName,
    required int quantity,
    required String? supplierName,
    required String? supplierEmail,
    required String? vendorEmail,
  }) async {
    await _placeAutomaticOrder(
      productName: productName,
      quantity: quantity,
      supplierName: supplierName,
      supplierEmail: supplierEmail,
      vendorEmail: vendorEmail,
    );
  }

  // Create sales records for analytics
  static Future<void> _createSalesRecords(SalesInvoice invoice, String invoiceId) async {
    try {
      final batch = _firestore.batch();
      
      for (final item in invoice.items) {
        final salesRecord = SalesRecord(
          id: '',
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
          soldAt: item.soldAt,
          invoiceId: invoiceId,
          vendorEmail: invoice.vendorEmail,
          notes: item.notes,
        );

        final docRef = _firestore.collection('sales_records').doc();
        batch.set(docRef, salesRecord.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Failed to create sales records: $e');
    }
  }

  // Get all invoices for a vendor
  static Future<List<SalesInvoice>> getInvoicesForVendor(String vendorEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('sales_invoices')
          .where('vendorEmail', isEqualTo: vendorEmail)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return SalesInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get invoices: $e');
    }
  }

  // Get latest invoice for a vendor
  static Future<SalesInvoice?> getLatestInvoice(String vendorEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('sales_invoices')
          .where('vendorEmail', isEqualTo: vendorEmail)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return SalesInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get latest invoice: $e');
    }
  }

  // Get invoices filtered by date range
  static Future<List<SalesInvoice>> getInvoicesByDateRange(
    String vendorEmail,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('sales_invoices')
          .where('vendorEmail', isEqualTo: vendorEmail)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return SalesInvoice.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get invoices by date range: $e');
    }
  }

  // Get sales analytics for a vendor
  static Future<Map<String, dynamic>> getSalesAnalytics(String vendorEmail, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('sales_records')
          .where('vendorEmail', isEqualTo: vendorEmail);

      if (startDate != null && endDate != null) {
        query = query
            .where('soldAt', isGreaterThanOrEqualTo: startDate)
            .where('soldAt', isLessThanOrEqualTo: endDate);
      }

      final querySnapshot = await query.get();
      
      final records = querySnapshot.docs.map((doc) {
        return SalesRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Calculate analytics
      double totalRevenue = records.fold(0.0, (sum, record) => sum + record.totalPrice);
      int totalItemsSold = records.fold(0, (sum, record) => sum + record.quantity);
      int totalTransactions = records.length;

      // Group by product
      final Map<String, int> productSales = {};
      final Map<String, double> productRevenue = {};
      
      for (final record in records) {
        productSales[record.productName] = (productSales[record.productName] ?? 0) + record.quantity;
        productRevenue[record.productName] = (productRevenue[record.productName] ?? 0.0) + record.totalPrice;
      }

      return {
        'totalRevenue': totalRevenue,
        'totalItemsSold': totalItemsSold,
        'totalTransactions': totalTransactions,
        'productSales': productSales,
        'productRevenue': productRevenue,
        'records': records,
      };
    } catch (e) {
      throw Exception('Failed to get sales analytics: $e');
    }
  }

  // Get available stock items for a vendor
  static Future<List<StockItem>> getAvailableStockItems(String vendorEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('stock_items')
          .where('currentStock', isGreaterThan: 0)
          .get();

      return querySnapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};
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
    } catch (e) {
      throw Exception('Failed to get available stock items: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getThresholdAndAutoOrderAnalysis({
    required String vendorEmail,
  }) async {
    // Fetch all sales records for this vendor
    final salesSnapshot = await _firestore
        .collection('sales_records')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    final Map<String, List<Map<String, dynamic>>> salesByProduct = {};
    for (final doc in salesSnapshot.docs) {
      final data = doc.data();
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final soldAt = data['soldAt'] is Timestamp ? (data['soldAt'] as Timestamp).toDate() : DateTime.now();
      final quantity = data['quantity'] ?? 0;
      salesByProduct.putIfAbsent(name, () => []).add({
        'soldAt': soldAt,
        'quantity': quantity,
      });
    }
    // Fetch current stock for this vendor
    final stockSnapshot = await _firestore
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    final List<Map<String, dynamic>> analysis = [];
    for (final doc in stockSnapshot.docs) {
      final data = doc.data();
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final currentStock = data['currentStock'] ?? 0;
      final minimumStock = data['minimumStock'] ?? 0;
      final sales = salesByProduct[name] ?? [];
      // Calculate sales velocity (units per week)
      double salesVelocity = 0;
      if (sales.isNotEmpty) {
        sales.sort((a, b) => (a['soldAt'] as DateTime).compareTo(b['soldAt'] as DateTime));
        final first = sales.first['soldAt'] as DateTime;
        final last = sales.last['soldAt'] as DateTime;
        final totalDays = last.difference(first).inDays + 1;
        final totalUnits = sales.fold<num>(0, (sum, s) => sum + (s['quantity'] ?? 0)).toDouble();
        salesVelocity = totalDays > 0 ? (totalUnits / (totalDays / 7.0)) : totalUnits;
      }
      // Recommend threshold: 1-2 weeks of sales velocity, min 1
      final recommendedThreshold = salesVelocity > 0 ? salesVelocity.ceil() * 2 : 1;
      // Priority: high if salesVelocity is high, low if slow
      final priority = salesVelocity > 10 ? 'High' : salesVelocity > 0 ? 'Medium' : 'Low';
      analysis.add({
        'productName': name,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
        'salesVelocity': salesVelocity,
        'recommendedThreshold': recommendedThreshold,
        'priority': priority,
      });
    }
    return analysis;
  }

  static Future<Map<String, dynamic>> analyzeSalesData({
    required String vendorEmail,
    required List<Map<String, dynamic>> sales,
    required String period,
  }) async {
    // Fetch initial stock for vendor
    final stockSnapshot = await _firestore
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    final stockMap = <String, int>{};
    for (final doc in stockSnapshot.docs) {
      final data = doc.data();
      final name = data['productName'] ?? '';
      final qty = data['currentStock'] ?? 0;
      stockMap[name.toLowerCase()] = qty;
    }
    // Aggregate sales
    final Map<String, int> soldMap = {};
    for (final sale in sales) {
      final name = (sale['productName'] ?? '').toString().toLowerCase();
      final qty = (sale['quantity'] ?? 0) is int ? (sale['quantity'] ?? 0) : ((sale['quantity'] ?? 0) as num).toInt();
      soldMap[name] = (((soldMap[name] ?? 0) as num) + qty).toInt();
    }
    // Analyze per product
    final List<Map<String, dynamic>> products = [];
    for (final entry in stockMap.entries) {
      final name = entry.key;
      final initialStock = entry.value;
      final sold = soldMap[name] ?? 0;
      final remaining = initialStock - sold;
      // Simple sales rate: sold/period (simulate for now)
      final salesRate = sold > 0 ? sold : 0;
      // Trend: up/down/steady (simulate)
      final trend = salesRate > 10 ? 'Up' : salesRate == 0 ? 'No sales' : 'Steady';
      // Reorder suggestion
      final reorderSuggestion = remaining < (initialStock * 0.2) ? 'Yes' : 'No';
      products.add({
        'productName': name,
        'initialStock': initialStock,
        'sold': sold,
        'remaining': remaining,
        'salesRate': salesRate,
        'trend': trend,
        'reorderSuggestion': reorderSuggestion,
      });
    }
    return {'products': products};
  }

  static Future<void> addInitialStockItem({
    required String vendorEmail,
    required String productName,
    required int initialQuantity,
    required double unitPrice,
    String? supplierName,
    String? notes,
  }) async {
    final stockRef = _firestore.collection('stock_items');
    // Check if stock item already exists for this vendor and product
    final query = await stockRef
        .where('vendorEmail', isEqualTo: vendorEmail)
        .where('productName', isEqualTo: productName)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      // Update existing stock item
      final doc = query.docs.first.reference;
      await doc.update({
        'currentStock': initialQuantity,
        'unitPrice': unitPrice,
        'supplierName': supplierName,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new stock item
      await stockRef.add({
        'vendorEmail': vendorEmail,
        'productName': productName,
        'currentStock': initialQuantity,
        'minimumStock': (initialQuantity * 0.1).round(),
        'maximumStock': initialQuantity,
        'unitPrice': unitPrice,
        'supplierName': supplierName,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static List<DeliveryRecord> _parseDeliveryHistory(List<dynamic> historyData) {
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

  static Future<void> checkAndCreateDraftOrders(String vendorEmail) async {
    final analysis = await getThresholdAndAutoOrderAnalysis(vendorEmail: vendorEmail);
    final stockSnapshot = await _firestore
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    for (final doc in stockSnapshot.docs) {
      final data = doc.data();
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final currentStock = data['currentStock'] ?? 0;
      final productAnalysis = analysis.firstWhere((a) => a['productName'] == name, orElse: () => <String, dynamic>{});
      if (productAnalysis.isNotEmpty && currentStock < productAnalysis['recommendedThreshold']) {
        // Check if a draft order already exists for this product
        final draftQuery = await _firestore.collection('draft_orders')
            .where('vendorEmail', isEqualTo: vendorEmail)
            .where('productName', isEqualTo: name)
            .where('status', isEqualTo: 'draft')
            .limit(1)
            .get();
        if (draftQuery.docs.isEmpty) {
          // Create draft order
          await _firestore.collection('draft_orders').add({
            'vendorEmail': vendorEmail,
            'productName': name,
            'suggestedQuantity': productAnalysis['recommendedThreshold'],
            'currentStock': currentStock,
            'analysis': productAnalysis,
            'status': 'draft',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getDraftOrders(String vendorEmail) async {
    final snapshot = await _firestore.collection('draft_orders')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .where('status', isEqualTo: 'draft')
        .get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  static Future<void> approveDraftOrder(String draftOrderId) async {
    final doc = _firestore.collection('draft_orders').doc(draftOrderId);
    await doc.update({'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()});
    // Optionally, create a real order here
  }

  static Future<void> rejectDraftOrder(String draftOrderId) async {
    final doc = _firestore.collection('draft_orders').doc(draftOrderId);
    await doc.update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> editDraftOrder(String draftOrderId, int newQuantity) async {
    final doc = _firestore.collection('draft_orders').doc(draftOrderId);
    await doc.update({'suggestedQuantity': newQuantity, 'editedAt': FieldValue.serverTimestamp()});
  }

  static Future<List<Map<String, dynamic>>> generateStockReport(String vendorEmail) async {
    final stockSnapshot = await _firestore
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    final salesSnapshot = await _firestore
        .collection('sales_records')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    final now = DateTime.now();
    final Map<String, List<Map<String, dynamic>>> salesByProduct = {};
    for (final doc in salesSnapshot.docs) {
      final data = doc.data();
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final soldAt = data['soldAt'] is Timestamp ? (data['soldAt'] as Timestamp).toDate() : now;
      final quantity = data['quantity'] ?? 0;
      salesByProduct.putIfAbsent(name, () => []).add({
        'soldAt': soldAt,
        'quantity': quantity,
      });
    }
    final List<Map<String, dynamic>> report = [];
    for (final doc in stockSnapshot.docs) {
      final data = doc.data();
      final name = (data['productName'] ?? '').toString().toLowerCase();
      final currentStock = data['currentStock'] ?? 0;
      final createdAt = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : now;
      final daysInStock = now.difference(createdAt).inDays;
      final sales = salesByProduct[name] ?? [];
      // Calculate sales rates
      int totalSold = 0;
      int soldLast7 = 0;
      int soldLast30 = 0;
      for (final s in sales) {
        final soldAt = s['soldAt'] as DateTime;
        final qty = (s['quantity'] ?? 0) is int ? (s['quantity'] ?? 0) : ((s['quantity'] ?? 0) as num).toInt();
        totalSold = (totalSold + qty).toInt();
        if (now.difference(soldAt).inDays <= 7) soldLast7 = (soldLast7 + qty).toInt();
        if (now.difference(soldAt).inDays <= 30) soldLast30 = (soldLast30 + qty).toInt();
      }
      final weeklyRate = soldLast7 / 1.0; // 1 week
      final monthlyRate = soldLast30 / 4.0; // 4 weeks
      // Depletion speed: days to zero at current weekly rate
      final depletionSpeed = weeklyRate > 0 ? (currentStock / weeklyRate).ceil() : null;
      // Recommended reorder level: 2x weekly rate or 1
      final reorderLevel = weeklyRate > 0 ? (weeklyRate * 2).ceil() : 1;
      // Priority score: weighted by sales rate and depletion speed
      final priorityScore = (weeklyRate * 2) + (depletionSpeed != null ? (30 - depletionSpeed) : 0);
      report.add({
        'productName': name,
        'currentStock': currentStock,
        'daysInStock': daysInStock,
        'weeklySalesRate': weeklyRate,
        'monthlySalesRate': monthlyRate,
        'depletionSpeedDays': depletionSpeed,
        'recommendedReorderLevel': reorderLevel,
        'priorityScore': priorityScore,
      });
    }
    return report;
  }
} 