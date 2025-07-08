import 'package:flutter/material.dart';
import '../models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryTrackingService {
  // This service handles tracking deliveries and updating stock information
  // In a real app, this would integrate with Firestore
  
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
    // 1. Create a DeliveryRecord (optional: you can store delivery history in stock_items or a separate collection)
    // 2. Update the corresponding StockItem (add or update)
    // 3. Update order status to 'Delivered'
    // 4. Trigger notifications if needed (not implemented here)

    final stockRef = FirebaseFirestore.instance.collection('stock_items').doc(productName);
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
          'notes': notes ?? '',
        });
        transaction.update(stockRef, {
          'currentStock': currentStock + quantity,
          'maximumStock': (stockSnapshot['maximumStock'] ?? 0) + quantity,
          'lastDeliveryDate': Timestamp.fromDate(deliveryDate),
          'deliveryHistory': deliveryHistory,
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
              'notes': notes ?? '',
            }
          ],
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
  }) async {
    final stockRef = FirebaseFirestore.instance.collection('stock_items').doc(productName);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final stockSnapshot = await transaction.get(stockRef);
      if (stockSnapshot.exists) {
        final currentStock = stockSnapshot['currentStock'] ?? 0;
        transaction.update(stockRef, {
          'currentStock': currentStock + deliveredQuantity,
          'maximumStock': (stockSnapshot['maximumStock'] ?? 0) + deliveredQuantity,
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
              'notes': '',
            }
          ],
        });
      }
    });
    print('Stock updated: $productName - Added $deliveredQuantity units');
  }
  
  static Future<bool> shouldTriggerAutoOrder(String productName) async {
    // TODO: Implement auto-order logic
    // This would check if stock is below minimum threshold
    // and if auto-order is enabled for the product
    
    return false;
  }
} 