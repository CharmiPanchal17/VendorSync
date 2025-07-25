import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String recipientId;
  final String senderId;
  final String type; // e.g., order_placed, order_confirmed, delivery, registration
  final Timestamp timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.recipientId,
    required this.senderId,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
} 