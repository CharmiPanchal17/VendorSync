
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class DeliveryTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> recordDelivery({
    required String orderId,
    required String productName,
    required int quantity,
    required String supplierName,
    required String supplierEmail,
    required DateTime deliveryDate,
    double? unitPrice,
    String? notes,
  }) async {
    try {
      // Create a delivery record
      final deliveryRecord = DeliveryRecord(
        id: 'del_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        productName: productName,
        quantity: quantity,
        supplierName: supplierName,
        supplierEmail: supplierEmail,
        deliveryDate: deliveryDate,
        unitPrice: unitPrice,
        notes: notes,
        status: 'Completed',
      );

      // Update stock levels automatically
      await updateStockLevels(
        productName: productName,
        deliveredQuantity: quantity,
        deliveryRecord: deliveryRecord,
      );

      // Update order status to 'Delivered'
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Delivered',
        'actualDeliveryDate': Timestamp.fromDate(deliveryDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Delivery recorded: $productName - $quantity units from $supplierName');
    } catch (e) {
      throw Exception('Failed to record delivery: $e');
    }
  }
  
  static Future<void> updateStockLevels({
    required String productName,
    required int deliveredQuantity,
    DeliveryRecord? deliveryRecord,
  }) async {
    try {
      // Find the stock item for the product
      final stockQuery = await _firestore
          .collection('stock_items')
          .where('productName', isEqualTo: productName)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final data = stockDoc.data();
        
        final currentStock = data['currentStock'] as int;
        final newCurrentStock = currentStock + deliveredQuantity;
        final newMaximumStock = newCurrentStock;

        // Update delivery history
        final deliveryHistory = List<Map<String, dynamic>>.from(data['deliveryHistory'] ?? []);
        if (deliveryRecord != null) {
          deliveryHistory.add({
            'id': deliveryRecord.id,
            'orderId': deliveryRecord.orderId,
            'productName': deliveryRecord.productName,
            'quantity': deliveryRecord.quantity,
            'supplierName': deliveryRecord.supplierName,
            'supplierEmail': deliveryRecord.supplierEmail,
            'deliveryDate': Timestamp.fromDate(deliveryRecord.deliveryDate),
            'unitPrice': deliveryRecord.unitPrice,
            'notes': deliveryRecord.notes,
            'status': deliveryRecord.status,
          });
        }

        // Calculate new average unit price
        final totalPrice = deliveryHistory
            .where((record) => record['unitPrice'] != null)
            .fold(0.0, (sum, record) => sum + (record['unitPrice'] as double));
        final totalDeliveries = deliveryHistory.length;
        final newAveragePrice = totalDeliveries > 0 ? totalPrice / totalDeliveries : deliveryRecord?.unitPrice;

        // Update the stock item
        await stockDoc.reference.update({
          'currentStock': newCurrentStock,
          'maximumStock': newMaximumStock,
          'deliveryHistory': deliveryHistory,
          'lastDeliveryDate': Timestamp.fromDate(DateTime.now()),
          'averageUnitPrice': newAveragePrice,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Check if auto-order should be triggered
        final shouldAutoOrder = await shouldTriggerAutoOrder(productName);
        if (shouldAutoOrder) {
          // TODO: Implement auto-order creation
          print('Auto-order should be triggered for $productName');
        }

        print('Stock updated: $productName - Added $deliveredQuantity units');
      } else {
        // Create new stock item if it doesn't exist
        if (deliveryRecord != null) {
          final newStockItem = {
            'productName': productName,
            'currentStock': deliveredQuantity,
            'minimumStock': 20, // Default minimum stock
            'maximumStock': deliveredQuantity,
            'deliveryHistory': [{
              'id': deliveryRecord.id,
              'orderId': deliveryRecord.orderId,
              'productName': deliveryRecord.productName,
              'quantity': deliveryRecord.quantity,
              'supplierName': deliveryRecord.supplierName,
              'supplierEmail': deliveryRecord.supplierEmail,
              'deliveryDate': Timestamp.fromDate(deliveryRecord.deliveryDate),
              'unitPrice': deliveryRecord.unitPrice,
              'notes': deliveryRecord.notes,
              'status': deliveryRecord.status,
            }],
            'primarySupplier': deliveryRecord.supplierName,
            'primarySupplierEmail': deliveryRecord.supplierEmail,
            'firstDeliveryDate': Timestamp.fromDate(DateTime.now()),
            'lastDeliveryDate': Timestamp.fromDate(DateTime.now()),
            'autoOrderEnabled': false,
            'averageUnitPrice': deliveryRecord.unitPrice,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          await _firestore.collection('stock_items').add(newStockItem);
          print('New stock item created: $productName');
        }
      }
    } catch (e) {
      throw Exception('Failed to update stock levels: $e');
    }
  }
  
  static Future<bool> shouldTriggerAutoOrder(String productName) async {
    try {
      final stockQuery = await _firestore
          .collection('stock_items')
          .where('productName', isEqualTo: productName)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final data = stockQuery.docs.first.data();
        final currentStock = data['currentStock'] as int;
        final minimumStock = data['minimumStock'] as int;
        final autoOrderEnabled = data['autoOrderEnabled'] as bool? ?? false;

        return autoOrderEnabled && currentStock <= minimumStock;
      }
      return false;
    } catch (e) {
      print('Error checking auto-order trigger: $e');
      return false;
    }
  }
} 