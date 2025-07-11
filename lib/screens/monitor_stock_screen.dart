import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';

const _maroon = Color(0xFF800000);
const _lightCyan = Color(0xFFAFFFFF);

class MonitorStockScreen extends StatefulWidget {
  final String vendorEmail;

  const MonitorStockScreen({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<MonitorStockScreen> createState() => _MonitorStockScreenState();
}

class _MonitorStockScreenState extends State<MonitorStockScreen> {
  List<StockItem> stockItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockItems();
  }

  Future<void> _loadStockItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load stock items from Firestore
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .get();

      final items = stockSnapshot.docs.map((doc) {
        final data = doc.data();
        return StockItem(
          id: doc.id,
          productName: data['productName'] ?? '',
          currentStock: data['currentStock'] ?? 0,
          minimumStock: data['minimumStock'] ?? 0,
          maximumStock: data['maximumStock'] ?? 0,
          deliveryHistory: _parseDeliveryHistory(data['deliveryHistory'] ?? []),
          primarySupplier: data['primarySupplier'],
          primarySupplierEmail: data['primarySupplierEmail'],
          firstDeliveryDate: data['firstDeliveryDate'] != null 
              ? (data['firstDeliveryDate'] as Timestamp).toDate() 
              : null,
          lastDeliveryDate: data['lastDeliveryDate'] != null 
              ? (data['lastDeliveryDate'] as Timestamp).toDate() 
              : null,
          autoOrderEnabled: data['autoOrderEnabled'] ?? false,
          averageUnitPrice: data['averageUnitPrice']?.toDouble(),
        );
      }).toList();

      setState(() {
        stockItems = items;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading stock items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<DeliveryRecord> _parseDeliveryHistory(List<dynamic> historyData) {
    return historyData.map((record) {
      return DeliveryRecord(
        id: record['id'] ?? '',
        orderId: record['orderId'] ?? '',
        productName: record['productName'] ?? '',
        quantity: record['quantity'] ?? 0,
        supplierName: record['supplierName'] ?? '',
        supplierEmail: record['supplierEmail'] ?? '',
        deliveryDate: record['deliveryDate'] != null 
            ? (record['deliveryDate'] as Timestamp).toDate() 
            : DateTime.now(),
        unitPrice: record['unitPrice']?.toDouble(),
        notes: record['notes'],
        status: record['status'] ?? 'Completed',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Monitor'),
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStockItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : _lightCyan,
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : stockItems.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildStockChart(isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _maroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bar_chart,
              color: _maroon,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Stock Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to your inventory to see stock monitoring charts',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockChart(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_maroon, _maroon.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Stock Level Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current stock levels as percentage of maximum capacity',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bar Chart
          Container(
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Stock Levels by Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDark ? Colors.white10 : Colors.white,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = stockItems[group.x.toInt()];
                            final percentage = item.maximumStock > 0 
                                ? (item.currentStock / item.maximumStock * 100)
                                : 0.0;
                            return BarTooltipItem(
                              '${item.productName}\n${percentage.toStringAsFixed(1)}% (${item.currentStock}/${item.maximumStock})',
                              TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
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
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= stockItems.length) {
                                return const SizedBox.shrink();
                              }
                              final item = stockItems[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SizedBox(
                                  width: 60,
                                  child: Text(
                                    item.productName.length > 8 
                                        ? '${item.productName.substring(0, 8)}...'
                                        : item.productName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white70 : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: stockItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final percentage = item.maximumStock > 0 
                            ? (item.currentStock / item.maximumStock * 100)
                            : 0.0;
                        final threshold = item.maximumStock > 0 
                            ? (item.minimumStock / item.maximumStock * 100)
                            : 20.0;
                        
                        Color barColor;
                        if (percentage <= threshold) {
                          barColor = Colors.red;
                        } else if (percentage <= threshold * 1.5) {
                          barColor = Colors.orange;
                        } else {
                          barColor = Colors.green;
                        }
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: percentage,
                              color: barColor,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 20,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Legend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Low Stock', Colors.red, isDark),
                    _buildLegendItem('Warning', Colors.orange, isDark),
                    _buildLegendItem('Good', Colors.green, isDark),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Products',
                  stockItems.length.toString(),
                  Icons.inventory,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Low Stock',
                  stockItems.where((item) {
                    final percentage = item.maximumStock > 0 
                        ? (item.currentStock / item.maximumStock * 100)
                        : 0.0;
                    final threshold = item.maximumStock > 0 
                        ? (item.minimumStock / item.maximumStock * 100)
                        : 20.0;
                    return percentage <= threshold;
                  }).length.toString(),
                  Icons.warning,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
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

  Widget _buildSummaryCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _maroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _maroon,
              size: 24,
            ),
          ),
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
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 