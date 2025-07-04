import 'package:flutter/material.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class StockManagementScreen extends StatelessWidget {
  // Replace with your actual product data source
  final List<Map<String, dynamic>> products = const [
    {
      'name': 'Product A',
      'currentStock': 25,
      'lastDelivered': 100,
      'autoOrderPending': false,
    },
    {
      'name': 'Product B',
      'currentStock': 10,
      'lastDelivered': 30,
      'autoOrderPending': true,
    },
  ];

  const StockManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                  : [maroon, maroon.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final percent = product['currentStock'] / product['lastDelivered'];
            final isLow = percent <= 0.3;
            return Card(
              color: isDark ? Colors.white10 : Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLow ? maroon.withOpacity(0.2) : Colors.grey.shade200,
                  child: Icon(Icons.inventory, color: isLow ? maroon : Colors.grey),
                ),
                title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock:  ${product['currentStock']} / ${product['lastDelivered']}'),
                    if (isLow)
                      Text(
                        product['autoOrderPending']
                            ? 'Auto-order pending...'
                            : 'Stock low! Auto-order will be placed.',
                        style: TextStyle(
                          color: maroon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: maroon),
                  onPressed: () {
                    // Show dialog to update stock
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 