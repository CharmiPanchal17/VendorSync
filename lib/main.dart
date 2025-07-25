import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const VendorSyncApp());
}

class VendorSyncApp extends StatelessWidget {
  const VendorSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendorSync',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register-suppliers': (context) => const RegisterSuppliersScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/vendor-dashboard': (context) => const VendorDashboardScreen(),
        '/vendor-create-order': (context) => const VendorCreateOrderScreen(),
        '/vendor-order-details': (context) => const VendorOrderDetailsScreen(),
        '/vendor-notifications': (context) => const VendorNotificationsScreen(),
        '/vendor-profile': (context) => const VendorProfileScreen(),
        '/supplier-dashboard': (context) => const SupplierDashboardScreen(),
        '/supplier-order-details': (context) => const SupplierOrderDetailsScreen(),
        '/supplier-delivery-schedule': (context) => const SupplierDeliveryScheduleScreen(),
        '/supplier-notifications': (context) => const SupplierNotificationsScreen(),
        '/supplier-profile': (context) => const SupplierProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class VendorNotificationsScreen extends StatelessWidget {
  const VendorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService _notificationService = NotificationService();
    final String userId = 'YOUR_TEST_USER_ID'; // Replace with actual user ID

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
                    // Optionally mark as read
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
