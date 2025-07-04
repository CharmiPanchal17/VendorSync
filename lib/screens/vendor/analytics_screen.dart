import 'package:flutter/material.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class AnalyticsScreen extends StatelessWidget {
  // Sample data - replace with your actual Firestore data
  final List<Map<String, dynamic>> salesData = const [
    {
      'product': 'Product A',
      'currentStock': 25,
      'lastDelivered': 100,
      'soldThisWeek': 15,
      'soldThisMonth': 45,
      'trend': 'decreasing',
    },
    {
      'product': 'Product B',
      'currentStock': 10,
      'lastDelivered': 30,
      'soldThisWeek': 8,
      'soldThisMonth': 22,
      'trend': 'stable',
    },
    {
      'product': 'Product C',
      'currentStock': 50,
      'lastDelivered': 80,
      'soldThisWeek': 12,
      'soldThisMonth': 35,
      'trend': 'increasing',
    },
  ];

  const AnalyticsScreen({super.key});

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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Products',
                    salesData.length.toString(),
                    Icons.inventory,
                    isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Low Stock Items',
                    salesData.where((item) => item['currentStock'] / item['lastDelivered'] <= 0.3).length.toString(),
                    Icons.warning,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sales Analytics Header
            Text(
              'Sales Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sales Data List
            ...salesData.map((item) => _buildSalesCard(item, isDark)).toList(),
          ],
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

  Widget _buildSalesCard(Map<String, dynamic> item, bool isDark) {
    final percent = item['currentStock'] / item['lastDelivered'];
    final isLow = percent <= 0.3;
    
    IconData trendIcon;
    Color trendColor;
    String trendText;
    
    switch (item['trend']) {
      case 'increasing':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Increasing';
        break;
      case 'decreasing':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Decreasing';
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orange;
        trendText = 'Stable';
    }

    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isLow ? maroon.withOpacity(0.2) : Colors.grey.shade200,
                  child: Icon(Icons.inventory, color: isLow ? maroon : Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stock: ${item['currentStock']} / ${item['lastDelivered']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(trendIcon, color: trendColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('This Week', item['soldThisWeek'].toString(), isDark),
                ),
                Expanded(
                  child: _buildMetricItem('This Month', item['soldThisMonth'].toString(), isDark),
                ),
                Expanded(
                  child: _buildMetricItem('Trend', trendText, isDark, color: trendColor),
                ),
              ],
            ),
            if (isLow) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Low Stock - Auto-order will be placed',
                  style: TextStyle(
                    color: maroon,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 