import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderPlaced,
  orderStatusChanged,
  orderDelivered,
  supplierAdded,
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
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientEmail,
    this.senderEmail,
    this.orderId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'recipientEmail': recipientEmail,
      'senderEmail': senderEmail,
      'orderId': orderId,
      'createdAt': createdAt,
      'isRead': isRead,
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
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }
} 