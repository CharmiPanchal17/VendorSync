import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_analytics_screen.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class AnalyticsScreen extends StatelessWidget {
  final String vendorEmail;
  const AnalyticsScreen({super.key, required this.vendorEmail});

  Future<List<Map<String, dynamic>>> _fetchStockData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stock_items')
        .where('vendorEmail', isEqualTo: vendorEmail)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
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
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStockData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading analytics'));
            }
            final stockData = snapshot.data ?? [];
            final lowStockCount = stockData.where((item) => (item['currentStock'] ?? 0) <= (item['minimumStock'] ?? 0)).length;
            return ListView(
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
                        lowStockCount.toString(),
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
                                      'Stock: ${item['currentStock']} / ${item['maximumStock']}',
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
                                      vendorEmail: vendorEmail,
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
            );
          },
        ),
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