import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_analytics_screen.dart';
import '../../services/sales_service.dart';
import 'package:fl_chart/fl_chart.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchStockData() async {
    final snapshot = await FirebaseFirestore.instance.collection('stock_items').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vendorEmail = ModalRoute.of(context)?.settings.arguments as String? ?? '';
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
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('sales_records')
              .where('vendorEmail', isEqualTo: vendorEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading analytics'));
            }
            final docs = snapshot.data?.docs ?? [];
            // Build daily sales data
            final Map<String, int> salesByDate = {};
            double totalRevenue = 0.0;
            int totalItemsSold = 0;
            int totalTransactions = docs.length;
            final Map<String, int> productSales = {};
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['soldAt'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? '';
              final qty = (data['quantity'] as num?)?.toInt() ?? 0;
              final price = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
              salesByDate[date] = (salesByDate[date] ?? 0) + qty;
              totalRevenue += price;
              totalItemsSold += qty;
              final product = data['productName'] ?? 'Unknown';
              productSales[product] = (productSales[product] ?? 0) + qty;
            }
            final dailySalesData = salesByDate.entries.map((e) => {'date': e.key, 'sales': e.value}).toList()
              ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Items Sold',
                        totalItemsSold.toString(),
                        Icons.shopping_cart,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Transactions',
                        totalTransactions.toString(),
                        Icons.receipt_long,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Sales Trend Graph
                Card(
                  color: isDark ? Colors.white10 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Trend (Quantity Sold)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (int i = 0; i < dailySalesData.length; i++)
                                      FlSpot(i.toDouble(), (dailySalesData[i]['sales'] as int).toDouble()),
                                  ],
                                  isCurved: true,
                                  color: maroon,
                                  barWidth: 3,
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < dailySalesData.length) {
                                        final date = dailySalesData[value.toInt()]['date'];
                                        return Text((date as String).substring(5)); // MM-DD
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Product Sales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : maroon)),
                const SizedBox(height: 12),
                ...productSales.entries.map((entry) => Card(
                  color: isDark ? Colors.white10 : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('Sold: ${entry.value}'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProductAnalyticsScreen(productName: entry.key, vendorEmail: vendorEmail),
                      ));
                    },
                  ),
                )),
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