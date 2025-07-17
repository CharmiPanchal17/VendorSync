
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> recordDelivery({
    required String orderId,
    required String productName,
    required int quantity,
    required String supplierName,
    required String supplierEmail,
    required DateTime deliveryDate,
    required String vendorEmail, // NEW PARAM
    double? unitPrice,
    String? notes,
  }) async {
    // 1. Create a DeliveryRecord (optional: you can store delivery history in stock_items or a separate collection)
    // 2. Update the corresponding StockItem (add or update)
    // 3. Update order status to 'Delivered'
    // 4. Trigger notifications if needed (not implemented here)

    final stockRef = FirebaseFirestore.instance.collection('stock_items').doc(productName + '_' + vendorEmail);
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

    // Use a transaction to ensure consistency
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final stockSnapshot = await transaction.get(stockRef);
      if (stockSnapshot.exists) {
        // Update existing stock item
        final currentStock = stockSnapshot['currentStock'] ?? 0;
        final deliveryHistory = List.from(stockSnapshot['deliveryHistory'] ?? []);
        deliveryHistory.add({
          'quantity': quantity,
          'deliveryDate': Timestamp.fromDate(deliveryDate),
          'supplierName': supplierName,
          'supplierEmail': supplierEmail,
          'vendorEmail': vendorEmail, // NEW FIELD
          'notes': notes ?? '',
        });
        transaction.update(stockRef, {
          'currentStock': currentStock + quantity,
          'maximumStock': (stockSnapshot['maximumStock'] ?? 0) + quantity,
          'lastDeliveryDate': Timestamp.fromDate(deliveryDate),
          'deliveryHistory': deliveryHistory,
          'vendorEmail': vendorEmail, // NEW FIELD
        });
      } else {
        // Create new stock item
        transaction.set(stockRef, {
          'productName': productName,
          'currentStock': quantity,
          'minimumStock': (quantity * 0.1).round(),
          'maximumStock': quantity,
          'firstDeliveryDate': Timestamp.fromDate(deliveryDate),
          'lastDeliveryDate': Timestamp.fromDate(deliveryDate),
          'deliveryHistory': [
            {
              'quantity': quantity,
              'deliveryDate': Timestamp.fromDate(deliveryDate),
              'supplierName': supplierName,
              'supplierEmail': supplierEmail,
              'vendorEmail': vendorEmail, // NEW FIELD
              'notes': notes ?? '',
            }
          ],
          'vendorEmail': vendorEmail, // NEW FIELD
        });
      }
      // Update order status to 'Delivered'
      transaction.update(orderRef, {
        'status': 'Delivered',
        'deliveredAt': Timestamp.fromDate(deliveryDate),
      });
    });
    print('Delivery recorded: $productName - $quantity units from $supplierName');
  }
  
  static Future<void> updateStockLevels({
    required String productName,
    required int deliveredQuantity,
    required String vendorEmail, // NEW PARAM
  }) async {
    final stockRef = FirebaseFirestore.instance.collection('stock_items').doc(productName + '_' + vendorEmail);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final stockSnapshot = await transaction.get(stockRef);
      if (stockSnapshot.exists) {
        final currentStock = stockSnapshot['currentStock'] ?? 0;
        transaction.update(stockRef, {
          'currentStock': currentStock + deliveredQuantity,
          'maximumStock': (stockSnapshot['maximumStock'] ?? 0) + deliveredQuantity,
          'vendorEmail': vendorEmail, // NEW FIELD
        });
      } else {
        transaction.set(stockRef, {
          'productName': productName,
          'currentStock': deliveredQuantity,
          'minimumStock': (deliveredQuantity * 0.1).round(),
          'maximumStock': deliveredQuantity,
          'firstDeliveryDate': Timestamp.now(),
          'lastDeliveryDate': Timestamp.now(),
          'deliveryHistory': [
            {
              'quantity': deliveredQuantity,
              'deliveryDate': Timestamp.now(),
              'supplierName': '',
              'supplierEmail': '',
              'vendorEmail': vendorEmail, // NEW FIELD
              'notes': '',
            }
          ],
          'vendorEmail': vendorEmail, // NEW FIELD
        });
      }
    });
    print('Stock updated: $productName - Added $deliveredQuantity units');
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