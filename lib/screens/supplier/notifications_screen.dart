import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';


class SupplierNotificationsScreen extends StatefulWidget {
  final String supplierEmail;
  
  const SupplierNotificationsScreen({super.key, required this.supplierEmail});

  @override
  State<SupplierNotificationsScreen> createState() => _SupplierNotificationsScreenState();
}

class _SupplierNotificationsScreenState extends State<SupplierNotificationsScreen> {
  @override
  Widget build(BuildContext context) {

      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
} 