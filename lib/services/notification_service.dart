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
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'recipientEmail': recipientEmail,
        'senderEmail': senderEmail,
        'orderId': orderId,
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
} 