import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import 'package:intl/intl.dart';

class VendorNotificationsScreen extends StatefulWidget {
  final String vendorEmail;
  
  const VendorNotificationsScreen({super.key, required this.vendorEmail});

  @override
  State<VendorNotificationsScreen> createState() => _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maroonNotification = Color(0xFF800000);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                : [maroonNotification, maroonNotification.withOpacity(0.8)],
            ),
          ),
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.getUnreadNotificationCount(widget.vendorEmail),
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
              await NotificationService.markAllNotificationsAsRead(widget.vendorEmail);
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
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)],
                )
              : null,
        ),
        child: StreamBuilder<List<AppNotification>>(
          stream: NotificationService.getNotificationsForUser(widget.vendorEmail),
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
                          color: isDark ? colorScheme.onSurface : maroonNotification,
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
                              : [const Color(0xFF2196F3), const Color(0xFF43E97B)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.notifications_none, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface : maroonNotification,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'ll see notifications here when suppliers confirm orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface.withOpacity(0.7) : maroonNotification.withOpacity(0.7),
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
                return _buildNotificationCard(notification, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    const maroonNotification = Color(0xFF800000);
    
    // Determine notification color based on type
    Color notificationColor;
    IconData notificationIcon;
    
    switch (notification.type) {
      case NotificationType.stockCritical:
        notificationColor = Colors.red;
        notificationIcon = Icons.warning;
        break;
      case NotificationType.thresholdAlert:
        notificationColor = Colors.orange;
        notificationIcon = Icons.warning_amber;
        break;
      case NotificationType.stockLow:
        notificationColor = Colors.blue;
        notificationIcon = Icons.info;
        break;
      case NotificationType.orderPlaced:
        notificationColor = Colors.green;
        notificationIcon = Icons.shopping_cart;
        break;
      case NotificationType.orderStatusChanged:
        notificationColor = Colors.blue;
        notificationIcon = Icons.update;
        break;
      case NotificationType.orderDelivered:
        notificationColor = Colors.green;
        notificationIcon = Icons.local_shipping;
        break;
      default:
        notificationColor = maroonNotification;
        notificationIcon = Icons.notifications;
    }

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
      child: Column(
        children: [
          ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: notification.isRead 
                              ? [Colors.grey.shade300, Colors.grey.shade400]
                      : [notificationColor, notificationColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                notificationIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: notification.isRead 
                            ? (isDark ? colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600)
                                                : (isDark ? colorScheme.onSurface : maroonNotification),
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
              _handleNotificationTap(notification);
                    },
                    onLongPress: () {
                      _showNotificationOptions(context, notification);
                    },
                  ),
          // Quick action buttons for threshold notifications
          if (_isThresholdNotification(notification.type) && notification.actionData != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToProductReports(notification),
                      icon: const Icon(Icons.analytics),
                      label: const Text('View Reports'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: maroonNotification,
                        side: BorderSide(color: maroonNotification),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToOrders(),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Review Orders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonNotification,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isThresholdNotification(NotificationType type) {
    return type == NotificationType.thresholdAlert ||
           type == NotificationType.stockLow ||
           type == NotificationType.stockCritical;
  }

  void _handleNotificationTap(AppNotification notification) {
    if (notification.orderId != null) {
      // Navigate to order details
      Navigator.of(context).pushNamed('/vendor-order-details');
    } else if (_isThresholdNotification(notification.type)) {
      // For threshold notifications, show options
      _showThresholdNotificationOptions(notification);
    }
  }

  void _navigateToProductReports(AppNotification notification) {
    if (notification.productName != null) {
      Navigator.of(context).pushNamed(
        '/vendor-product-analytics',
        arguments: notification.productName,
      );
    }
  }

  void _navigateToQuickOrder(AppNotification notification) {
    if (notification.actionData != null) {
      final actionData = notification.actionData!;
      Navigator.of(context).pushNamed(
        '/vendor-quick-order',
        arguments: {
          'productName': actionData['productName'] ?? notification.productName ?? '',
          'suggestedQuantity': actionData['suggestedQuantity'] ?? 0,
          'supplierEmail': actionData['supplierEmail'],
          'supplierName': actionData['supplierName'],
          'vendorEmail': widget.vendorEmail,
        },
      );
    }
  }

  void _navigateToOrders() {
    Navigator.of(context).pushNamed('/vendor-orders', arguments: widget.vendorEmail);
  }

  void _showThresholdNotificationOptions(AppNotification notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maroonNotification = Color(0xFF800000);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Threshold Alert Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.analytics, color: maroonNotification),
              title: Text(
                'View Product Reports',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToProductReports(notification);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: maroonNotification),
              title: Text(
                'Review Orders',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToOrders();
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: maroonNotification),
              title: Text(
                'Manage Thresholds',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/vendor-threshold-management', arguments: widget.vendorEmail);
              },
            ),
          ],
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
        return Icons.warning;
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
                  color: isDark ? colorScheme.primary : Colors.blue,
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