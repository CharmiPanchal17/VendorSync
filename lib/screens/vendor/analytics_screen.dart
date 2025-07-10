import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_analytics_screen.dart';
import '../../mock_data/mock_orders.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class AnalyticsScreen extends StatefulWidget {
  final String vendorEmail;
  const AnalyticsScreen({Key? key, required this.vendorEmail}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> stockData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      setState(() { isLoading = true; });
      final currentVendorEmail = widget.vendorEmail;
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: currentVendorEmail)
          .get();
      if (stockSnapshot.docs.isNotEmpty) {
        setState(() {
          stockData = stockSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        // Try to create from orders or fallback to mock data
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'Delivered')
            .where('vendorEmail', isEqualTo: currentVendorEmail)
            .get();
        if (ordersSnapshot.docs.isNotEmpty) {
          // Group orders by product name
          final Map<String, List<QueryDocumentSnapshot>> productGroups = {};
          for (final doc in ordersSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final productName = data['productName'] as String? ?? 'Unknown Product';
            productGroups.putIfAbsent(productName, () => []).add(doc);
          }
          final List<Map<String, dynamic>> realStockData = [];
          for (final entry in productGroups.entries) {
            final productName = entry.key;
            final orders = entry.value;
            int totalDelivered = 0;
            double totalPrice = 0;
            int priceCount = 0;
            int minimumStock = 0;
            int maximumStock = 0;
            int currentStock = 0;
            for (final orderDoc in orders) {
              final data = orderDoc.data() as Map<String, dynamic>;
              final quantity = data['quantity'] as int? ?? 0;
              final unitPrice = data['unitPrice'] as double?;
              totalDelivered += quantity;
              if (unitPrice != null) {
                totalPrice += unitPrice;
                priceCount++;
              }
            }
            currentStock = (totalDelivered * 0.7).round();
            minimumStock = (totalDelivered * 0.1).round();
            maximumStock = totalDelivered;
            final averageUnitPrice = priceCount > 0 ? totalPrice / priceCount : null;
            realStockData.add({
              'productName': productName,
              'currentStock': currentStock,
              'minimumStock': minimumStock,
              'maximumStock': maximumStock,
              'averageUnitPrice': averageUnitPrice,
              'vendorEmail': currentVendorEmail,
            });
          }
          setState(() {
            stockData = realStockData;
            isLoading = false;
          });
          await _saveStockDataToFirestore(realStockData);
        } else {
          // Fallback to mock data
          setState(() {
            stockData = mockStockItems.map((item) => {
              'productName': item.productName,
              'currentStock': item.currentStock,
              'minimumStock': item.minimumStock,
              'maximumStock': item.maximumStock,
              'averageUnitPrice': item.averageUnitPrice,
              'vendorEmail': item.vendorEmail,
            }).toList();
            isLoading = false;
          });
          await _saveStockDataToFirestore(stockData);
        }
      }
    } catch (e) {
      setState(() {
        stockData = mockStockItems.map((item) => {
          'productName': item.productName,
          'currentStock': item.currentStock,
          'minimumStock': item.minimumStock,
          'maximumStock': item.maximumStock,
          'averageUnitPrice': item.averageUnitPrice,
          'vendorEmail': item.vendorEmail,
        }).toList();
        isLoading = false;
      });
      await _saveStockDataToFirestore(stockData);
    }
  }

  Future<void> _saveStockDataToFirestore(List<Map<String, dynamic>> stockData) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in stockData) {
        final docId = item['productName'] + '_' + (item['vendorEmail'] ?? widget.vendorEmail);
        final docRef = FirebaseFirestore.instance.collection('stock_items').doc(docId);
        batch.set(docRef, item);
      }
      await batch.commit();
      // print('Analytics stock data saved to Firestore successfully');
    } catch (e) {
      // print('Error saving analytics stock data to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stockData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: isDark ? Colors.white24 : Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No stock data yet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add products or receive deliveries to see analytics.',
                        style: TextStyle(fontSize: 16, color: isDark ? Colors.white38 : Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Products',
                            stockData.length.toString(),
                            Icons.inventory,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Low Stock Items',
                            stockData.where((item) => (item['currentStock'] ?? 0) <= (item['minimumStock'] ?? 0)).length.toString(),
                            Icons.warning,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Product Cards
                    ...stockData.map((item) {
                      final isLow = (item['currentStock'] ?? 0) <= (item['minimumStock'] ?? 0);
                      return Card(
                        color: isLow ? Colors.red.shade50 : (isDark ? Colors.white10 : Colors.white),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['productName'] ?? 'Unknown Product',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "Stock:  9${item['currentStock']} / ${item['maximumStock']}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark ? Colors.white70 : Colors.grey[600],
                                          ),
                                        ),
                                        if (isLow)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              'Low Stock',
                                              style: TextStyle(
                                                color: maroon,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.show_chart, color: maroon),
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => ProductAnalyticsScreen(
                                          productName: item['productName'] ?? 'Unknown Product',
                                        ),
                                      ));
                                    },
                                  ),
                                ],
                              ),
                              // You can add more analytics here (trend, sales, etc.)
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: maroon, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 