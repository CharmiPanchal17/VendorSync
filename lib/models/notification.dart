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
  bool isRead; // Removed final to make it mutable

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
      orderId: map['orderId'],
      createdAt: createdAt,
      isRead: map['isRead'] ?? false,
    );
  }
} 