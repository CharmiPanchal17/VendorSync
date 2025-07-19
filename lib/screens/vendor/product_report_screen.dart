import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class ProductReportScreen extends StatelessWidget {
  final String productName;
  
  const ProductReportScreen({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    return Scaffold(
      appBar: AppBar(
        title: Text('$productName Report'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _printReport(context),
            tooltip: 'Download Report',
          ),
        ],
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
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(maroon),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: maroon.withOpacity(0.6)),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading report data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
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
              'date': d,
              'formattedDate': _formatDate(d),
              'sales': salesByDay[_formatDate(d)] ?? 0,
            }).toList();

            final totalSales = dailySalesData.fold<int>(0, (sum, item) => sum + (item['sales'] as int));
            final avgSales = dailySalesData.isNotEmpty ? (totalSales / dailySalesData.length).round() : 0;
            final maxSales = dailySalesData.isNotEmpty ? dailySalesData.map((e) => e['sales'] as int).reduce((a, b) => a > b ? a : b) : 0;
            final minSales = dailySalesData.isNotEmpty ? dailySalesData.map((e) => e['sales'] as int).reduce((a, b) => a < b ? a : b) : 0;

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('stock_items')
                  .where('productName', isEqualTo: productName)
                  .limit(1)
                  .get(),
              builder: (context, stockSnapshot) {
                int? currentStock;
                if (stockSnapshot.hasData && stockSnapshot.data!.docs.isNotEmpty) {
                  final data = stockSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  currentStock = data['currentStock'] as int?;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Report Header
                    _buildReportHeader(isDark, currentStock),
                    const SizedBox(height: 24),
                    
                    // Summary Statistics
                    _buildSummaryStats(isDark, totalSales, avgSales, maxSales, minSales),
                    const SizedBox(height: 24),
                    
                    // Daily Sales Table
                    _buildDailySalesTable(isDark, dailySalesData, currentStock),
                    const SizedBox(height: 24),
                    
                    // Report Footer
                    _buildReportFooter(isDark),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportHeader(bool isDark, int? currentStock) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [maroon.withOpacity(0.2), maroon.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: maroon.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.assessment, color: maroon, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Report',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: maroon,
                        ),
                      ),
                      Text(
                        'Last 7 Days Performance',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (currentStock != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: maroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: maroon.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: maroon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Current Stock: $currentStock units',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: maroon,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(bool isDark, int totalSales, int avgSales, int maxSales, int minSales) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Sales', totalSales.toString(), Icons.trending_up, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Average Daily', avgSales.toString(), Icons.analytics, isDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Highest Day', maxSales.toString(), Icons.arrow_upward, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Lowest Day', minSales.toString(), Icons.arrow_downward, isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroon.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: maroon, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesTable(bool isDark, List<Map<String, dynamic>> dailySalesData, int? currentStock) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Sales Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: maroon.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: maroon,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Sales',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: maroon,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (currentStock != null)
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: maroon,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Table Rows
            ...dailySalesData.map((item) => _buildTableRow(item, isDark, currentStock)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item, bool isDark, int? currentStock) {
    final date = item['date'] as DateTime;
    final sales = item['sales'] as int;
    final dayName = _getDayName(date.weekday);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  item['formattedDate'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$sales units',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: maroon,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (currentStock != null)
            Expanded(
              flex: 1,
              child: Text(
                '$currentStock',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportFooter(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.verified, color: maroon, size: 32),
            const SizedBox(height: 12),
            Text(
              'Report Generated',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data accurate as of ${_formatDate(DateTime.now())}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printReport(BuildContext context) async {
    try {
      // Gather report data (last 7 days sales for the product)
      final now = DateTime.now();
      final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
      final salesSnapshot = await FirebaseFirestore.instance
          .collection('sales_history')
          .where('productName', isEqualTo: productName)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(last7Days.first))
          .get();
      final salesDocs = salesSnapshot.docs;
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
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Date', 'Sales'],
        ...last7Days.map((d) => [_formatDate(d), salesByDay[_formatDate(d)] ?? 0]),
      ];
      String csv = const ListToCsvConverter().convert(csvData);
      // Show preview dialog before saving
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Preview'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: (csvData.isNotEmpty)
                      ? (csvData[0] as List)
                          .map<DataColumn>((col) => DataColumn(label: Text(col.toString(), style: const TextStyle(fontWeight: FontWeight.bold))))
                          .toList()
                      : [],
                  rows: csvData.length > 1
                      ? csvData
                          .sublist(1)
                          .map<DataRow>((row) => DataRow(
                                cells: (row as List)
                                    .map<DataCell>((cell) => DataCell(Text(cell.toString())))
                                    .toList(),
                              ))
                          .toList()
                      : [],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Let user pick location
                  final fileName = '${productName}_sales_report_${_formatDate(DateTime.now())}.csv';
                  final path = await getSavePath(suggestedName: fileName);
                  if (path != null) {
                    final file = XFile.fromData(
                      csv.codeUnits,
                      name: fileName,
                      mimeType: 'text/csv',
                    );
                    await file.saveTo(path);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Report downloaded to $path'),
                          backgroundColor: maroon,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Download'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
} 