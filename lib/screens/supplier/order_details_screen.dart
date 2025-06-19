import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class SupplierOrderDetailsScreen extends StatefulWidget {
  const SupplierOrderDetailsScreen({super.key});

  @override
  State<SupplierOrderDetailsScreen> createState() => _SupplierOrderDetailsScreenState();
}

class _SupplierOrderDetailsScreenState extends State<SupplierOrderDetailsScreen> {
  String? status;
  DateTime? deliveryDate;

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    status ??= order.status;
    deliveryDate ??= order.actualDeliveryDate;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Product: ${order.productName}', style: const TextStyle(fontSize: 18)),
            Text('Vendor: ${order.supplierName}'),
            Text('Quantity: ${order.quantity}'),
            Text('Preferred Delivery: ${DateFormat.yMMMd().format(order.preferredDeliveryDate)}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: status,
              items: const [
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
              ],
              onChanged: (val) => setState(() => status = val),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(deliveryDate == null
                  ? 'Set Delivery Date'
                  : 'Delivery Date: ${DateFormat.yMMMd().format(deliveryDate!)}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => deliveryDate = picked);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Update Order'),
            ),
          ],
        ),
      ),
    );
  }
} 