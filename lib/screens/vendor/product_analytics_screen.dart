import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class ProductAnalyticsScreen extends StatelessWidget {
  final String productName;
  
  const ProductAnalyticsScreen({super.key, required this.productName});

  // Sample daily sales data - replace with your actual Firestore data
  List<Map<String, dynamic>> get dailySalesData => [
    {'date': '2024-06-01', 'sales': 5, 'stock': 100},
    {'date': '2024-06-02', 'sales': 8, 'stock': 95},
    {'date': '2024-06-03', 'sales': 12, 'stock': 87},
    {'date': '2024-06-04', 'sales': 6, 'stock': 81},
    {'date': '2024-06-05', 'sales': 15, 'stock': 75},
    {'date': '2024-06-06', 'sales': 9, 'stock': 66},
    {'date': '2024-06-07', 'sales': 11, 'stock': 57},
    {'date': '2024-06-08', 'sales': 7, 'stock': 50},
    {'date': '2024-06-09', 'sales': 13, 'stock': 43},
    {'date': '2024-06-10', 'sales': 10, 'stock': 33},
    {'date': '2024-06-11', 'sales': 8, 'stock': 25},
    {'date': '2024-06-12', 'sales': 14, 'stock': 17},
    {'date': '2024-06-13', 'sales': 6, 'stock': 11},
    {'date': '2024-06-14', 'sales': 9, 'stock': 5},
  ];

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
        child: ListView(
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
                            dailySalesData.fold<int>(0, (sum, item) => sum + item['sales']).toString(),
                            Icons.trending_up,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            'Avg Daily',
                            (dailySalesData.fold<int>(0, (sum, item) => sum + item['sales']) / dailySalesData.length).round().toString(),
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
                            item['sales'] > max ? item['sales'] : max
                          ).toDouble() + 2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: dailySalesData.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value['sales'].toDouble());
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
                    ...dailySalesData.map((item) => _buildDailySalesRow(item, isDark)).toList(),
                  ],
                ),
              ),
            ),
          ],
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