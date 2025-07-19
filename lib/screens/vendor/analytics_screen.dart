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
      if (!mounted) return;
      setState(() { isLoading = true; });
      final currentVendorEmail = widget.vendorEmail;
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: currentVendorEmail)
          .get();
      if (stockSnapshot.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          stockData = stockSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          stockData = [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stockData = [];
        isLoading = false;
      });
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
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(maroon),
                ),
              )
            : stockData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No analytics data',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deliver products to see analytics here.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white38 : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary Cards
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildEnhancedSummaryCard(
                                'Total Products',
                                stockData.length.toString(),
                                Icons.inventory_2,
                                isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildEnhancedSummaryCard(
                                'Low Stock Items',
                                stockData.where((item) => (item['currentStock'] ?? 0) <= (item['minimumStock'] ?? 0)).length.toString(),
                                Icons.warning_amber,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Product Cards
                      ...stockData.map((item) {
                        final isLow = (item['currentStock'] ?? 0) <= (item['minimumStock'] ?? 0);
                        return _buildEnhancedProductCard(item, isLow, isDark, context);
                      }).toList(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEnhancedSummaryCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [maroon.withOpacity(0.2), maroon.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: maroon.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: maroon,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProductCard(Map<String, dynamic> item, bool isLow, bool isDark, BuildContext context) {
    final currentStock = item['currentStock'] ?? 0;
    final maximumStock = item['maximumStock'] ?? 0;
    final minimumStock = item['minimumStock'] ?? 0;
    final stockPercentage = maximumStock > 0 ? currentStock / maximumStock : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isLow
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: isLow
                ? Colors.red.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLow
                          ? [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)]
                          : [maroon.withOpacity(0.2), maroon.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLow ? Colors.red.withOpacity(0.3) : maroon.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isLow ? Icons.warning : Icons.inventory,
                    color: isLow ? Colors.red : maroon,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['productName'] ?? 'Unknown Product',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLow
                                  ? Colors.red.withOpacity(0.2)
                                  : maroon.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLow ? 'Low Stock' : 'In Stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLow ? Colors.red : maroon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [maroon.withOpacity(0.1), maroon.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: maroon.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.analytics, color: maroon, size: 20),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProductAnalyticsScreen(
                          productName: item['productName'] ?? 'Unknown Product',
                        ),
                      ));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Stock Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Level',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${(stockPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isLow ? Colors.red : maroon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.7 * stockPercentage,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLow
                              ? [Colors.red, Colors.red.withOpacity(0.7)]
                              : [maroon, maroon.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentStock units',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                    Text(
                      '$maximumStock units',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stock Metrics
            Row(
              children: [
                Expanded(
                  child: _buildStockMetric(
                    'Current',
                    currentStock.toString(),
                    Icons.inventory,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockMetric(
                    'Min',
                    minimumStock.toString(),
                    Icons.warning,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStockMetric(
                    'Max',
                    maximumStock.toString(),
                    Icons.storage,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockMetric(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: maroon.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: maroon,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 