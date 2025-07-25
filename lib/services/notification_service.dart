import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final _notifications = FirebaseFirestore.instance.collection('notifications');

  Stream<List<AppNotification>> getNotificationsForUser(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  Future<void> sendNotification(AppNotification notification) async {
    await _notifications.add(notification.toMap());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }
} 