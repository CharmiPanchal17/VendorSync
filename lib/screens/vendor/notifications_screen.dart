import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';

const _maroonVendor = Color(0xFF800000);
const _lightCyanVendor = Color(0xFFAFFFFF);

class VendorNotificationsScreen extends StatefulWidget {
  final String vendorEmail;
  
  const VendorNotificationsScreen({super.key, required this.vendorEmail});

  @override
  State<VendorNotificationsScreen> createState() => _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
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