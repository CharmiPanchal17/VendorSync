import 'package:flutter/material.dart';
import '../../mock_data/mock_orders.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class SupplierDeliveryScheduleScreen extends StatelessWidget {
  const SupplierDeliveryScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming = mockOrders.where((o) => o.status == 'Confirmed' || o.status == 'Shipped').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Schedule')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: upcoming.length,
        itemBuilder: (context, index) {
          final order = upcoming[index];
          return Card(
            child: ListTile(
              title: Text(order.productName),
              subtitle: Text('Vendor: ${order.supplierName}\nDelivery: ${DateFormat.yMMMd().format(order.preferredDeliveryDate)}'),
              trailing: Text(order.status),
            ),
          );
        },
      ),
    );
  }
} 