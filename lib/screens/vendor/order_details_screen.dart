import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'package:intl/intl.dart';

class VendorOrderDetailsScreen extends StatelessWidget {
  const VendorOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as Order;
    final statusIndex = _statusIndex(order.status);
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${order.productName}', style: const TextStyle(fontSize: 18)),
            Text('Supplier: ${order.supplierName}'),
            Text('Quantity: ${order.quantity}'),
            Text('Preferred Delivery: ${DateFormat.yMMMd().format(order.preferredDeliveryDate)}'),
            if (order.actualDeliveryDate != null)
              Text('Delivered: ${DateFormat.yMMMd().format(order.actualDeliveryDate!)}'),
            const SizedBox(height: 24),
            Stepper(
              currentStep: statusIndex,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: const [
                Step(title: Text('Placed'), content: SizedBox()),
                Step(title: Text('Confirmed'), content: SizedBox()),
                Step(title: Text('Shipped'), content: SizedBox()),
                Step(title: Text('Delivered'), content: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'Confirmed':
        return 1;
      case 'Shipped':
        return 2;
      case 'Delivered':
        return 3;
      default:
        return 0;
    }
  }
} 