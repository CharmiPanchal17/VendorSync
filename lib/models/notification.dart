// Trigger rebuild: file touched to clear build cache issues
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderPlaced,
  orderStatusChanged,
  orderDelivered,
  supplierAdded,

  thresholdAlert,
  stockLow,
  stockCritical,
  final String message;
  final NotificationType type;
  final String recipientEmail;
  final String? senderEmail;
  final String? orderId;
  final String? productName;
  final int? stockLevel;
  final int? thresholdLevel;
  final DateTime createdAt;


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

    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

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

      productName: map['productName'],
      stockLevel: map['stockLevel'],
      thresholdLevel: map['thresholdLevel'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      actionData: map['actionData'],
    );
  }
} 