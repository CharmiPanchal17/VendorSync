import 'package:flutter/material.dart';
import '../../mock_data/mock_orders.dart';

class SupplierDashboardScreen extends StatelessWidget {
  const SupplierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final ordersToday = mockOrders.where((o) => o.preferredDeliveryDate.day == today.day && o.preferredDeliveryDate.month == today.month && o.preferredDeliveryDate.year == today.year).length;
    final pendingDeliveries = mockOrders.where((o) => o.status == 'Confirmed').length;
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
                        child: Icon(Icons.local_shipping, size: 32, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, Supplier!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Manage your orders and deliveries', style: Theme.of(context).textTheme.bodyMedium),
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
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Delivery Schedule'),
                    style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/supplier-delivery-schedule');
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('Notifications'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/supplier-notifications');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(label: 'Orders Today', value: ordersToday.toString()),
                  _StatCard(label: 'Pending Deliveries', value: pendingDeliveries.toString()),
                ],
              ),
              const SizedBox(height: 24),
              Text('New Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: mockOrders.length,
                  itemBuilder: (context, index) {
                    final order = mockOrders[index];
                    if (order.status != 'Pending') return const SizedBox.shrink();
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
                        subtitle: Text('Vendor: ${order.supplierName}\nQuantity: ${order.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed('/supplier-order-details', arguments: order);
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
} 