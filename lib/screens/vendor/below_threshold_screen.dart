import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Add any other necessary imports for StockItem, NotificationService, etc.

const _maroon = Color(0xFF800000);
const _lightCyan = Color(0xFFAFFFFF);

class BelowThresholdScreen extends StatefulWidget {
  final String vendorEmail;
  const BelowThresholdScreen({super.key, required this.vendorEmail});

  @override
  State<BelowThresholdScreen> createState() => _BelowThresholdScreenState();
}

class _BelowThresholdScreenState extends State<BelowThresholdScreen> {
  List<StockItem> belowThresholdItems = [];
  Map<String, int> manualOrderQuantities = {};
  bool isLoading = true;
  Map<String, Map<String, String>> selectedSuppliers = {}; // {stockItemId: {name, email}}
  List<Map<String, String>> suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadBelowThresholdItems();
    _loadSuppliers();
  }

  Future<void> _loadBelowThresholdItems() async {
    setState(() { isLoading = true; });
    final stockSnapshot = await FirebaseFirestore.instance
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: widget.vendorEmail)
        .get();
    final allItems = stockSnapshot.docs.map((doc) {
      final data = doc.data();
      return StockItem(
        id: doc.id,
        productName: data['productName'] ?? '',
        currentStock: data['currentStock'] ?? 0,
        minimumStock: data['minimumStock'] ?? 0,
        maximumStock: data['maximumStock'] ?? 0,
        deliveryHistory: [], // Simplified for now
        primarySupplier: data['primarySupplier'],
        primarySupplierEmail: data['primarySupplierEmail'],
        firstDeliveryDate: null,
        lastDeliveryDate: null,
        autoOrderEnabled: data['autoOrderEnabled'] ?? false,
        averageUnitPrice: data['averageUnitPrice']?.toDouble(),
      );
    }).toList();
    final belowThreshold = allItems.where((item) {
      final percentage = item.maximumStock > 0 
          ? (item.currentStock / item.maximumStock * 100)
          : 0.0;
      final threshold = item.maximumStock > 0 
          ? (item.minimumStock / item.maximumStock * 100)
          : 20.0;
      return percentage <= threshold;
    }).toList();
    setState(() {
      belowThresholdItems = belowThreshold;
      isLoading = false;
    });
  }

  Future<void> _loadSuppliers() async {
    final snapshot = await FirebaseFirestore.instance.collection('suppliers').get();
    setState(() {
      suppliers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': (data['name'] ?? 'Unknown').toString(),
          'email': (data['email'] ?? '').toString(),
        };
      }).toList();
    });
  }

  Future<void> _placeManualOrder(StockItem item) async {
    final supplier = selectedSuppliers[item.id];
    if (supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier before placing an order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // ... Place order logic ...
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed for ${item.productName} with ${supplier['name']}')),
    );
  }

  Future<Map<String, dynamic>> _fetchProductAnalytics(String productName) async {
    // Simulate analytics for now
    return {
      'totalSold': 10,
      'soldLast7': 2,
      'soldLast30': 5,
      'weeklyRate': 2.0,
      'monthlyRate': 5.0,
      'trend': 'Steady',
      'duration': 30,
      'reorderSuggestion': 'Yes',
      'firstSale': DateTime.now().subtract(const Duration(days: 30)),
      'lastSale': DateTime.now(),
    };
  }

  void _showProductReport(BuildContext context, StockItem item) async {
    final analytics = await _fetchProductAnalytics(item.productName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report: ${item.productName}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Metric')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    DataRow(cells: [DataCell(Text('Total Sold')), DataCell(Text('${analytics['totalSold']}'))]),
                    DataRow(cells: [DataCell(Text('Sold Last 7 Days')), DataCell(Text('${analytics['soldLast7']}'))]),
                    DataRow(cells: [DataCell(Text('Sold Last 30 Days')), DataCell(Text('${analytics['soldLast30']}'))]),
                    DataRow(cells: [DataCell(Text('Weekly Sales Rate')), DataCell(Text('${analytics['weeklyRate']}'))]),
                    DataRow(cells: [DataCell(Text('Monthly Sales Rate')), DataCell(Text('${analytics['monthlyRate']}'))]),
                    DataRow(cells: [DataCell(Text('Trend')), DataCell(Text('${analytics['trend']}'))]),
                    DataRow(cells: [DataCell(Text('Duration in Stock (days)')), DataCell(Text('${analytics['duration']}'))]),
                    DataRow(cells: [DataCell(Text('Suggested Reorder Qty')), DataCell(Text('${analytics['reorderSuggestion']}'))]),
                  ],
                ),
                const SizedBox(height: 16),
                if (analytics['firstSale'] != null && analytics['lastSale'] != null)
                  Text('Sales from: ${analytics['firstSale']} to ${analytics['lastSale']}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierDropdown(StockItem item) {
    final selected = selectedSuppliers[item.id];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selected?['email'],
            hint: const Text('Select Supplier'),
            items: suppliers.map((s) => DropdownMenuItem(
              value: s['email'],
              child: Text('${s['name']} (${s['email']})'),
            )).toList(),
            onChanged: (value) {
              final supplier = suppliers.firstWhere((s) => s['email'] == value);
              setState(() {
                selectedSuppliers[item.id] = supplier;
              });
            },
            validator: (v) => v == null ? 'Select supplier' : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Below Threshold Alerts')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: belowThresholdItems.length,
              itemBuilder: (context, index) {
                final item = belowThresholdItems[index];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Current Stock: ${item.currentStock}'),
                        _buildSupplierDropdown(item),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _placeManualOrder(item),
                              child: const Text('Order'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.analytics),
                              label: const Text('View Product Report'),
                              onPressed: () => _showProductReport(context, item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Dummy StockItem class for context (replace with your actual model)
class StockItem {
  final String id;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final List<dynamic> deliveryHistory;
  final String? primarySupplier;
  final String? primarySupplierEmail;
  final DateTime? firstDeliveryDate;
  final DateTime? lastDeliveryDate;
  final bool autoOrderEnabled;
  final double? averageUnitPrice;
  StockItem({
    required this.id,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.deliveryHistory,
    this.primarySupplier,
    this.primarySupplierEmail,
    this.firstDeliveryDate,
    this.lastDeliveryDate,
    this.autoOrderEnabled = false,
    this.averageUnitPrice,
  });
} 