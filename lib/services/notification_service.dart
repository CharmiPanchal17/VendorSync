import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new notification
  static Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String recipientEmail,
    String? senderEmail,
    String? orderId,
    String? productName,
    int? stockLevel,
    int? thresholdLevel,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'recipientEmail': recipientEmail,
        'senderEmail': senderEmail,
        'orderId': orderId,
        'productName': productName,
        'stockLevel': stockLevel,
        'thresholdLevel': thresholdLevel,
        'actionData': actionData,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Get notifications for a specific user
  static Stream<List<AppNotification>> getNotificationsForUser(String userEmail) {
    return _firestore
        .collection('notifications')
        .where('recipientEmail', isEqualTo: userEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllNotificationsAsRead(String userEmail) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('recipientEmail', isEqualTo: userEmail)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount(String userEmail) {
    return _firestore
        .collection('notifications')
        .where('recipientEmail', isEqualTo: userEmail)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Create order placed notification for supplier
  static Future<void> notifySupplierOfNewOrder({
    required String supplierEmail,
    required String vendorEmail,
    required String orderId,
    required String productName,
    required int quantity,
  }) async {
    final vendorQuery = await _firestore
        .collection('vendors')
        .where('email', isEqualTo: vendorEmail)
        .limit(1)
        .get();

    String vendorName = 'A vendor';
    if (vendorQuery.docs.isNotEmpty) {
      vendorName = vendorQuery.docs.first['name'] ?? 'A vendor';
    }

    await createNotification(
      title: 'New Order Received',
      message: '$vendorName has placed a new order for $quantity $productName',
      type: NotificationType.orderPlaced,
      recipientEmail: supplierEmail,
      senderEmail: vendorEmail,
      orderId: orderId,
    );
  }
  
  // Create order confirmed notification for vendor
  static Future<void> notifyVendorOfOrderConfirmation({
    required String vendorEmail,
    required String supplierEmail,
    required String orderId,
    required String productName,
    required int quantity,
  }) async {
    final supplierQuery = await _firestore
        .collection('suppliers')
        .where('email', isEqualTo: supplierEmail)
        .limit(1)
        .get();

    String supplierName = 'A supplier';
    if (supplierQuery.docs.isNotEmpty) {
      supplierName = supplierQuery.docs.first['name'] ?? 'A supplier';
    }

    await createNotification(
      title: 'Order Confirmed',
      message: '$supplierName has confirmed your order for $quantity $productName',
      type: NotificationType.orderStatusChanged,
      recipientEmail: vendorEmail,
      senderEmail: supplierEmail,
      orderId: orderId,
    );
  }

  // Create threshold alert notification
  static Future<void> createThresholdAlert({
    required String vendorEmail,
    required String productName,
    required int currentStock,
    required int thresholdLevel,
    required String thresholdStatus,
    String? supplierEmail,
    String? supplierName,
    int? suggestedQuantity,
  }) async {
    String title;
    String message;
    NotificationType type;

    switch (thresholdStatus) {
      case 'critical':
        title = 'Critical Stock Alert';
        message = '$productName is critically low! Current stock: $currentStock (Threshold: $thresholdLevel)';
        type = NotificationType.stockCritical;
        break;
      case 'warning':
        title = 'Stock Threshold Alert';
        message = '$productName has reached threshold level. Current stock: $currentStock (Threshold: $thresholdLevel)';
        type = NotificationType.thresholdAlert;
        break;
      default:
        title = 'Low Stock Alert';
        message = '$productName stock is running low. Current stock: $currentStock (Threshold: $thresholdLevel)';
        type = NotificationType.stockLow;
    }

    final actionData = {
      'productName': productName,
      'currentStock': currentStock,
      'thresholdLevel': thresholdLevel,
      'supplierEmail': supplierEmail,
      'supplierName': supplierName,
      'suggestedQuantity': suggestedQuantity,
      'actionType': 'order_now',
    };

    await createNotification(
      title: title,
      message: message,
      type: type,
      recipientEmail: vendorEmail,
      productName: productName,
      stockLevel: currentStock,
      thresholdLevel: thresholdLevel,
      actionData: actionData,
    );
  }

  // Check and create threshold alerts for all products (no auto-ordering)
  static Future<void> checkThresholdAlerts(String vendorEmail) async {
    try {
      final stockSnapshot = await _firestore
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: vendorEmail)
          .where('thresholdNotificationsEnabled', isEqualTo: true)
          .get();

      for (final doc in stockSnapshot.docs) {
        final data = doc.data();
        final currentStock = data['currentStock'] as int? ?? 0;
        final thresholdLevel = data['thresholdLevel'] as int? ?? 0;
        final minimumStock = data['minimumStock'] as int? ?? 0;
        final productName = data['productName'] as String? ?? '';
        final lastThresholdAlert = data['lastThresholdAlert'] as Timestamp?;
        final supplierEmail = data['primarySupplierEmail'] as String?;
        final supplierName = data['primarySupplier'] as String?;

        // Skip if no threshold is set
        if (thresholdLevel == 0) continue;

        // Check if we should send an alert
        bool shouldAlert = false;
        String thresholdStatus = '';

        if (currentStock <= (minimumStock * 0.5)) {
          shouldAlert = true;
          thresholdStatus = 'critical';
        } else if (currentStock <= thresholdLevel) {
          shouldAlert = true;
          thresholdStatus = 'warning';
        } else if (currentStock <= (minimumStock * 1.2)) {
          shouldAlert = true;
          thresholdStatus = 'info';
        }

        if (shouldAlert) {
          // Check if we've already alerted recently (within 24 hours)
          final lastAlert = lastThresholdAlert?.toDate();
          final shouldSendAlert = lastAlert == null || 
              DateTime.now().difference(lastAlert).inHours >= 24;

          if (shouldSendAlert) {
            // Calculate suggested quantity for reference only
            final suggestedQuantity = _calculateSuggestedQuantity(data);

            await createThresholdAlert(
              vendorEmail: vendorEmail,
              productName: productName,
              currentStock: currentStock,
              thresholdLevel: thresholdLevel,
              thresholdStatus: thresholdStatus,
              supplierEmail: supplierEmail,
              supplierName: supplierName,
              suggestedQuantity: suggestedQuantity,
            );

            // Update last threshold alert timestamp
            await _firestore
                .collection('stock_items')
                .doc(doc.id)
                .update({'lastThresholdAlert': FieldValue.serverTimestamp()});
          }
        }
      }
    } catch (e) {
      print('Error checking threshold alerts: $e');
    }
  }

  // Calculate suggested order quantity based on historical data
  static int _calculateSuggestedQuantity(Map<String, dynamic> stockData) {
    final deliveryHistory = stockData['deliveryHistory'] as List<dynamic>? ?? [];
    final minimumStock = stockData['minimumStock'] as int? ?? 0;

    if (deliveryHistory.isEmpty) return minimumStock;

    // Calculate average daily usage from recent deliveries (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentDeliveries = deliveryHistory.where((delivery) {
      final deliveryDate = (delivery['deliveryDate'] as Timestamp).toDate();
      return deliveryDate.isAfter(thirtyDaysAgo);
    }).toList();

    if (recentDeliveries.isEmpty) return minimumStock;

    final totalQuantity = recentDeliveries.fold<int>(0, (sum, delivery) {
      return sum + (delivery['quantity'] as int? ?? 0);
    });

    final avgDailyUsage = totalQuantity / 30; // Assume 30 days
    final suggestedQuantity = (avgDailyUsage * 14 * 1.2).round(); // 2 weeks + 20% buffer
    
    return suggestedQuantity > 0 ? suggestedQuantity : minimumStock;
  }

  // Show a simple notification (for delivery confirmation)
  static void showNotification(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 