import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
// TODO: Import your Firebase notification service when created

class VendorNotificationsScreen extends StatelessWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService _notificationService = NotificationService();
    final String userId = 'test_vendor_id'; // Replace with actual user ID

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.getNotificationsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.notifications, color: notification.isRead ? Colors.grey : Theme.of(context).colorScheme.primary),
                  title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notification.message),
                  trailing: Text(
                    _formatTimestamp(notification.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    _notificationService.markAsRead(notification.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
} 