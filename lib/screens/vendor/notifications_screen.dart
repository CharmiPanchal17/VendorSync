import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VendorNotificationsScreen extends StatelessWidget {
  final String vendorEmail;
  const VendorNotificationsScreen({super.key, this.vendorEmail = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientEmail', isEqualTo: vendorEmail)
              .where('recipientType', isEqualTo: 'vendor')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading notifications'));
            }
            final notifications = snapshot.data?.docs ?? [];
            if (notifications.isEmpty) {
              return Center(child: Text('No notifications yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index].data() as Map<String, dynamic>;
                final createdAt = notification['createdAt'] as Timestamp?;
                final isRead = notification['isRead'] ?? false;
                return Card(
                  color: isRead ? Colors.white : Colors.blue.shade50,
                  child: ListTile(
                    leading: Icon(Icons.notifications, color: isRead ? Colors.grey : Colors.blue),
                    title: Text(notification['title'] ?? 'Notification'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message'] ?? ''),
                        if (createdAt != null)
                          Text(DateFormat('MMM dd, yyyy - HH:mm').format(createdAt.toDate()),
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: !isRead ? const Icon(Icons.fiber_manual_record, color: Colors.blue, size: 12) : null,
                    onTap: () {
                      FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notifications[index].id)
                          .update({'isRead': true});
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
} 