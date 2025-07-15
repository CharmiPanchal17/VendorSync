import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderPlaced,
  orderStatusChanged,
  orderDelivered,
  supplierAdded,
  thresholdAlert,
  stockLow,
  stockCritical,
  general
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String recipientEmail;
  final String? senderEmail;
  final String? orderId;
  final String? productName;
  final int? stockLevel;
  final int? thresholdLevel;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? actionData;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientEmail,
    this.senderEmail,
    this.orderId,
    this.productName,
    this.stockLevel,
    this.thresholdLevel,
    required this.createdAt,
    this.isRead = false,
    this.actionData,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'recipientEmail': recipientEmail,
      'senderEmail': senderEmail,
      'orderId': orderId,
      'productName': productName,
      'stockLevel': stockLevel,
      'thresholdLevel': thresholdLevel,
      'createdAt': createdAt,
      'isRead': isRead,
      'actionData': actionData,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NotificationType.general,
      ),
      recipientEmail: map['recipientEmail'] ?? '',
      senderEmail: map['senderEmail'],
      orderId: map['orderId'],
      productName: map['productName'],
      stockLevel: map['stockLevel'],
      thresholdLevel: map['thresholdLevel'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      actionData: map['actionData'],
    );
  }
} 