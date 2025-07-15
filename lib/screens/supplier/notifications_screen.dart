import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import 'package:intl/intl.dart';

class SupplierNotificationsScreen extends StatefulWidget {
  final String supplierEmail;
  
  const SupplierNotificationsScreen({super.key, required this.supplierEmail});

  @override
  State<SupplierNotificationsScreen> createState() => _SupplierNotificationsScreenState();
}

class _SupplierNotificationsScreenState extends State<SupplierNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDark ? Colors.transparent : const Color(0xFF800000),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: isDark
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D3D3D), Color(0xFF2D2D2D)],
                  ),
                ),
              )
            : null,
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.getUnreadNotificationCount(widget.supplierEmail),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () async {
              await NotificationService.markAllNotificationsAsRead(widget.supplierEmail);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications marked as read'),
                    backgroundColor: isDark ? Colors.green.shade700 : Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : const Color(0xFFAFFFFF),
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                )
              : null,
        ),
        child: StreamBuilder<List<AppNotification>>(
          stream: NotificationService.getNotificationsForUser(widget.supplierEmail),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                              ? [colorScheme.primary, colorScheme.secondary]
                              : [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.notifications_none, size: 48, color: isDark ? Colors.white : Color(0xFF800000)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'ll see notifications here when vendors place orders',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: notification.isRead 
                              ? [Colors.grey.shade300, Colors.grey.shade400]
                              : (isDark 
                                  ? [colorScheme.primary, colorScheme.secondary]
                                  : [const Color(0xFF800000), const Color(0xFF800000)]),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: isDark ? Colors.white : Color(0xFF800000),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: notification.isRead 
                            ? (isDark ? colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600)
                            : (isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A)),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMd().add_jm().format(notification.createdAt),
                          style: TextStyle(
                            color: isDark ? colorScheme.onSurface.withOpacity(0.5) : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: notification.isRead 
                        ? null 
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () async {
                      if (!notification.isRead) {
                        await NotificationService.markNotificationAsRead(notification.id);
                      }
                      // TODO: Navigate to order details if it's an order notification
                    },
                    onLongPress: () {
                      _showNotificationOptions(context, notification);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return Icons.shopping_cart;
      case NotificationType.orderStatusChanged:
        return Icons.update;
      case NotificationType.orderDelivered:
        return Icons.local_shipping;
      case NotificationType.supplierAdded:
        return Icons.person_add;

      case NotificationType.thresholdAlert:
        return Icons.warning_amber;
      case NotificationType.stockLow:
        return Icons.info;
      case NotificationType.stockCritical:
        return Icons.war
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  void _showNotificationOptions(BuildContext context, AppNotification notification) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Notification',
                style: TextStyle(
                  color: isDark ? colorScheme.onSurface : Colors.black,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await NotificationService.deleteNotification(notification.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification deleted'),
                      backgroundColor: isDark ? Colors.red.shade700 : Colors.red,
                    ),
                  );
                }
              },
            ),
            if (!notification.isRead)
              ListTile(
                leading: Icon(
                  Icons.mark_email_read, 
                  color: isDark ? Colors.white : Color(0xFF800000),
                ),
                title: Text(
                  'Mark as Read',
                  style: TextStyle(
                    color: isDark ? colorScheme.onSurface : Colors.black,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationService.markNotificationAsRead(notification.id);
                },
              ),
          ],
        ),
      ),
    );
  }
} 