import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/sales_service.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class ProductAnalyticsScreen extends StatelessWidget {
  final String productName;
  final String vendorEmail;
  
  const ProductAnalyticsScreen({super.key, required this.productName, required this.vendorEmail});

  Future<List<Map<String, dynamic>>> _fetchProductSalesData() async {
    final analytics = await SalesService.getSalesAnalytics(vendorEmail);
    final records = analytics['records'] as List<dynamic>? ?? [];
    final productRecords = records.where((r) => r.productName == productName).toList();
    // Group by date
    final Map<String, int> salesByDate = {};
    for (final record in productRecords) {
      final date = record.soldAt.toString().substring(0, 10);
      final qty = (record.quantity as num).toInt();
      final prev = salesByDate[date] ?? 0;
      salesByDate[date] = (prev + qty).toInt();
    }
    return salesByDate.entries.map((e) => {'date': e.key, 'sales': e.value}).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchProductSalesData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading product analytics'));
            }
            final dailySalesData = snapshot.data ?? [];

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
                            dailySalesData.fold<int>(0, (sum, item) => sum + (item['sales'] as int)).toString(),
                            Icons.trending_up,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            'Avg Daily',
                            (dailySalesData.fold<int>(0, (sum, item) => sum + (item['sales'] as int)) / dailySalesData.length).round().toString(),
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
                      'Daily Sales Trend',
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
                                interval: 2,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  if (value.toInt() >= 0 && value.toInt() < dailySalesData.length) {
                                    final date = dailySalesData[value.toInt()]['date'];
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        date.substring(5), // Show MM-DD format
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
                                interval: 5,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                reservedSize: 42,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                          minX: 0,
                          maxX: (dailySalesData.length - 1).toDouble(),
                          minY: 0,
                          maxY: dailySalesData.fold<int>(0, (max, item) => 
                            (item['sales'] as int) > max ? (item['sales'] as int) : max
                          ).toDouble() + 2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: dailySalesData.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), (entry.value['sales'] as int).toDouble());
                              }).toList(),
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [maroon, maroon.withOpacity(0.5)],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: maroon,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    maroon.withOpacity(0.3),
                                    maroon.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
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
                    ...dailySalesData.map((item) => _buildDailySalesRow(item, isDark)),
                  ],
                ),
              ),
            ),
          ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: maroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: maroon, size: 24),
          const SizedBox(height: 4),
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
} 