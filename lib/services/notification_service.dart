import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import '../services/auth_service.dart'; // Added missing import for AuthService

class NotificationService {
  // Mock notifications data
  static final Map<String, List<AppNotification>> _mockNotifications = {};

  // Create a new notification
  static Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String recipientEmail,
    String? senderEmail,
    String? orderId,
    bool? showOrderNowButton,
    int? suggestedQuantity,
    String? supplierName,
    String? supplierEmail,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        recipientEmail: recipientEmail,
        senderEmail: senderEmail,
        orderId: orderId,
        createdAt: DateTime.now(),
        isRead: false,
        showOrderNowButton: showOrderNowButton,
        suggestedQuantity: suggestedQuantity,
        supplierName: supplierName,
        supplierEmail: supplierEmail,
      );

      if (!_mockNotifications.containsKey(recipientEmail)) {
        _mockNotifications[recipientEmail] = [];
      }
      _mockNotifications[recipientEmail]!.add(notification);
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get notifications for a specific user
  static Stream<List<AppNotification>> getNotificationsForUser(String userEmail) {
    return Stream.value(_mockNotifications[userEmail] ?? []);
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      for (var notifications in _mockNotifications.values) {
        for (var notification in notifications) {
          if (notification.id == notificationId) {
            notification.isRead = true;
            break;
          }
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  static Future<void> markAllNotificationsAsRead(String userEmail) async {
    try {
      if (_mockNotifications.containsKey(userEmail)) {
        for (var notification in _mockNotifications[userEmail]!) {
          notification.isRead = true;
        }
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount(String userEmail) {
    final notifications = _mockNotifications[userEmail] ?? [];
    final unreadCount = notifications.where((n) => !n.isRead).length;
    return Stream.value(unreadCount);
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      for (var notifications in _mockNotifications.values) {
        notifications.removeWhere((n) => n.id == notificationId);
      }
    } catch (e) {
      print('Error deleting notification: $e');
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
    String vendorName = 'A vendor';
    try {
      final query = await FirebaseFirestore.instance
        .collection('vendors')
        .where('email', isEqualTo: vendorEmail)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        vendorName = query.docs.first['name'] ?? 'A vendor';
      }
    } catch (e) {
      print('Error fetching vendor name: $e');
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
    String supplierName = 'A supplier';
    try {
      final query = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('email', isEqualTo: supplierEmail)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        supplierName = query.docs.first['name'] ?? 'A supplier';
      }
    } catch (e) {
      print('Error fetching supplier name: $e');
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

  // Send a stock threshold notification to the vendor
  static Future<void> sendStockThresholdNotification({
    required String vendorEmail,
    required String productName,
    required int currentStock,
    required int threshold,
    required String? supplierName,
    required String? supplierEmail,
    required int suggestedQuantity,
  }) async {
    final title = 'Stock Alert: $productName';
    final message =
        'Stock for $productName has reached the threshold ($currentStock left, threshold: $threshold). Supplier: ${supplierName ?? 'N/A'}.';
    await createNotification(
      recipientEmail: vendorEmail,
      title: title,
      message: message,
      type: NotificationType.stockThreshold,
      showOrderNowButton: true,
      suggestedQuantity: suggestedQuantity,
      supplierName: supplierName,
      supplierEmail: supplierEmail,
      // Optionally, you can add more fields to AppNotification if needed
    );
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

  // Notify supplier of auto-order
  static Future<void> notifySupplierOfAutoOrder({
    required String vendorEmail,
    required String supplierEmail,
    required String orderId,
    required String productName,
    required int quantity,
    required int currentStock,
    required int threshold,
  }) async {
    String vendorName = 'A vendor';
    try {
      final query = await FirebaseFirestore.instance
        .collection('vendors')
        .where('email', isEqualTo: vendorEmail)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        vendorName = query.docs.first['name'] ?? 'A vendor';
      }
    } catch (e) {
      print('Error fetching vendor name: $e');
    }

    await createNotification(
      title: 'Auto-Order Generated',
      message: 'An automatic order has been generated for $quantity $productName due to low stock levels (current: $currentStock, threshold: $threshold)',
      type: NotificationType.orderPlaced,
      recipientEmail: supplierEmail,
      senderEmail: vendorEmail,
      orderId: orderId,
    );
  }

  // Notify vendor of auto-order
  static Future<void> notifyVendorOfAutoOrder({
    required String vendorEmail,
    required String supplierEmail,
    required String orderId,
    required String productName,
    required int quantity,
    required int currentStock,
    required int threshold,
  }) async {
    String supplierName = 'A supplier';
    try {
      final query = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('email', isEqualTo: supplierEmail)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        supplierName = query.docs.first['name'] ?? 'A supplier';
      }
    } catch (e) {
      print('Error fetching supplier name: $e');
    }

    await createNotification(
      title: 'Auto-Order Created',
      message: 'An automatic order for $quantity $productName has been sent to $supplierName due to low stock (current: $currentStock, threshold: $threshold)',
      type: NotificationType.stockThreshold,
      recipientEmail: vendorEmail,
      senderEmail: supplierEmail,
      orderId: orderId,
    );
  }
} 