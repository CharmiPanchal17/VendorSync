import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
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
    // Get vendor name from mock data
    final authService = AuthService();
    final vendor = authService.mockUsers[vendorEmail];
    if (vendor != null) {
      vendorName = vendor['name'] ?? 'A vendor';
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
    // Get supplier name from mock data
    final authService = AuthService();
    final supplier = authService.mockUsers[supplierEmail];
    if (supplier != null) {
      supplierName = supplier['name'] ?? 'A supplier';
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