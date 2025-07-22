import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_report_screen.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class ProductAnalyticsScreen extends StatelessWidget {
  final String productName;
  
  const ProductAnalyticsScreen({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    return Scaffold(
      appBar: AppBar(
        title: Text('$productName Analytics'),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sales_history')
              .where('productName', isEqualTo: productName)
              .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(last7Days.first))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading sales data'));
            }
            final salesDocs = snapshot.data?.docs ?? [];
            // Aggregate sales by day
            final Map<String, int> salesByDay = {for (var d in last7Days) _formatDate(d): 0};
            for (final doc in salesDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'];
              if (ts is Timestamp) {
                final date = DateTime(ts.toDate().year, ts.toDate().month, ts.toDate().day);
                final key = _formatDate(date);
                if (salesByDay.containsKey(key)) {
                  salesByDay[key] = salesByDay[key]! + ((data['quantity'] ?? 0) as int);
                }
              }
            }
            final dailySalesData = last7Days.map((d) => {
              'date': _formatDate(d),
              'sales': salesByDay[_formatDate(d)] ?? 0,
            }).toList();
            final totalSales = dailySalesData.fold<int>(0, (sum, item) => sum + (item['sales'] as int));
            final avgSales = dailySalesData.isNotEmpty ? (totalSales / dailySalesData.length).round() : 0;
            // Debug print to check for negative sales data
            print('Daily sales data: ' + dailySalesData.map((e) => e['sales']).toList().toString());
            // Replace the FutureBuilder for stock_items with a StreamBuilder for real-time updates
            // Find the section where the stock level is fetched for the product
            // Replace:
            //   FutureBuilder<QuerySnapshot>(
            //     future: FirebaseFirestore.instance
            //         .collection('stock_items')
            //         .where('productName', isEqualTo: productName)
            //         .limit(1)
            //         .get(),
            //     builder: (context, stockSnapshot) { ... }
            //   )
            // With:
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stock_items')
                  .where('productName', isEqualTo: productName)
                  .limit(1)
                  .snapshots(),
              builder: (context, stockSnapshot) {
                int? currentStock;
                if (stockSnapshot.hasData && stockSnapshot.data!.docs.isNotEmpty) {
                  final data = stockSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  currentStock = data['currentStock'] as int?;
                }
                // --- Dynamic interval calculation here ---
                final maxY = dailySalesData.isNotEmpty ? dailySalesData.map((e) => e['sales'] as int).reduce((a, b) => a > b ? a : b) : 0;
                int interval;
                if (maxY <= 50) {
                  interval = 10;
                } else if (maxY <= 200) {
                  interval = 20;
                } else if (maxY <= 1000) {
                  interval = 100;
                } else {
                  interval = 200;
                }
                // --- End dynamic interval calculation ---
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Product Summary Card
                    Card(
                      color: isDark ? Colors.white10 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: maroon.withOpacity(0.2),
                                  child: Icon(Icons.inventory, color: maroon),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Daily Sales Analytics',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ),
                                      if (currentStock != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'Current Stock: $currentStock',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'Total Sales',
                                    totalSales.toString(),
                                    Icons.trending_up,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Avg Daily',
                                    avgSales.toString(),
                                    Icons.analytics,
                                    isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sales Graph
                    Card(
                      color: isDark ? Colors.white10 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Sales Trend (Last 7 Days)',
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
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: 5,
                                    verticalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: 1,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value.toInt() >= 0 && value.toInt() < dailySalesData.length) {
                                            final dateObj = dailySalesData[value.toInt()]['date'];
                                            final dateStr = dateObj is String ? dateObj : dateObj.toString();
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(
                                                dateStr.substring(5), // Show MM-DD format
                                                style: TextStyle(
                                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: interval.toDouble(),
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          if (value % interval == 0) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            );
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  minX: 0,
                                  maxX: (dailySalesData.length - 1).toDouble(),
                                  minY: 0,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (int i = 0; i < dailySalesData.length; i++)
                                          FlSpot(i.toDouble(), (dailySalesData[i]['sales'] as int).toDouble()),
                                      ],
                                      isCurved: true,
                                      preventCurveOverShooting: true,
                                      color: maroon,
                                      barWidth: 2, // Reduced thickness for a thinner line
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: maroon.withOpacity(0.15),
                                      ),
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                          radius: 2, // Increased dot size by one
                                          color: maroon,
                                          strokeWidth: 0,
                                          strokeColor: maroon,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (totalSales == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: Text(
                                    'No sales in the last 7 days',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Daily Sales Table
                    Card(
                      color: isDark ? Colors.white10 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Sales Breakdown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...dailySalesData.map((item) => _buildDailySalesRow({...item, 'stock': currentStock}, isDark)).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Card(
                      color: isDark ? Colors.white10 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _navigateToDetailedReports(context),
                                icon: const Icon(Icons.assessment),
                                label: const Text('Generate Report'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: maroon,
                                  side: BorderSide(color: maroon),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetailedReports(BuildContext context) {
    // Navigate to the new clean report screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductReportScreen(productName: productName),
      ),
    );
  }



  Widget _buildMetricCard(String title, String value, IconData icon, bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: maroon, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesRow(Map<String, dynamic> item, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item['date'],
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item['sales']} units',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Stock: ${item['stock']}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 