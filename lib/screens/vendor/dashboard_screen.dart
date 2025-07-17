import 'package:flutter/material.dart';
import '../../mock_data/mock_orders.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.store, size: 32, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, Vendor!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Manage your orders and suppliers', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Order'),
                    style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/vendor-create-order');
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Register Supplier'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register-suppliers');
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notifications'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/vendor-notifications');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: mockOrders.length,
                  itemBuilder: (context, index) {
                    final order = mockOrders[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.inventory, color: colorScheme.primary),
                        ),
                        title: Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Supplier: ${order.supplierName}\nQuantity: ${order.quantity}'),
                        trailing: Chip(
                          label: Text(order.status),
                          backgroundColor: _statusColor(order.status),
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed('/vendor-order-details', arguments: order);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade100;
      case 'Confirmed':
        return Colors.blue.shade100;
      case 'Delivered':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
} 