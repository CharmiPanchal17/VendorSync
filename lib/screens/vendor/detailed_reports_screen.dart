import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const maroonReports = Color(0xFF800000);
const lightCyanReports = Color(0xFFAFFFFF);

class DetailedReportsScreen extends StatefulWidget {
  final String productName;
  
  const DetailedReportsScreen({super.key, required this.productName});

  @override
  State<DetailedReportsScreen> createState() => _DetailedReportsScreenState();
}

class _DetailedReportsScreenState extends State<DetailedReportsScreen> {
  bool isLoading = true;
  Map<String, dynamic> productData = {};
  List<Map<String, dynamic>> salesHistory = [];
  List<Map<String, dynamic>> orderHistory = [];
  List<Map<String, dynamic>> supplierPerformance = [];

  @override
  void initState() {
    super.initState();
    _loadDetailedReports();
  }

  Future<void> _loadDetailedReports() async {
    try {
      setState(() { isLoading = true; });
      
      // Load product stock data
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('productName', isEqualTo: widget.productName)
          .limit(1)
          .get();

      if (stockSnapshot.docs.isNotEmpty) {
        productData = stockSnapshot.docs.first.data();
      }

      // Load sales history (mock data for now)
      salesHistory = [
        {'date': '2024-01-01', 'sales': 45, 'revenue': 2250.0},
        {'date': '2024-01-02', 'sales': 52, 'revenue': 2600.0},
        {'date': '2024-01-03', 'sales': 38, 'revenue': 1900.0},
        {'date': '2024-01-04', 'sales': 61, 'revenue': 3050.0},
        {'date': '2024-01-05', 'sales': 47, 'revenue': 2350.0},
        {'date': '2024-01-06', 'sales': 55, 'revenue': 2750.0},
        {'date': '2024-01-07', 'sales': 42, 'revenue': 2100.0},
      ];

      // Load order history
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('productName', isEqualTo: widget.productName)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      orderHistory = ordersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'orderId': doc.id,
          'quantity': data['quantity'] ?? 0,
          'status': data['status'] ?? 'Unknown',
          'supplierName': data['supplierName'] ?? 'Unknown',
          'createdAt': data['createdAt'] as Timestamp?,
          'deliveryDate': data['preferredDeliveryDate'] as Timestamp?,
          'unitPrice': data['unitPrice']?.toDouble(),
        };
      }).toList();

      // Load supplier performance data
      supplierPerformance = [
        {
          'supplierName': 'ABC Supplies',
          'totalOrders': 15,
          'onTimeDelivery': 12,
          'averageRating': 4.2,
          'totalSpent': 15000.0,
        },
        {
          'supplierName': 'XYZ Corporation',
          'totalOrders': 8,
          'onTimeDelivery': 7,
          'averageRating': 4.5,
          'totalSpent': 8500.0,
        },
      ];

      setState(() { isLoading = false; });
    } catch (e) {
      print('Error loading detailed reports: $e');
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.productName} - Detailed Reports'),
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
                  : [maroonReports, maroonReports.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyanReports,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductOverview(isDark),
                    const SizedBox(height: 24),
                    _buildSalesAnalysis(isDark),
                    const SizedBox(height: 24),
                    _buildOrderHistory(isDark),
                    const SizedBox(height: 24),
                    _buildSupplierPerformance(isDark),
                    const SizedBox(height: 24),
                    _buildActionButtons(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProductOverview(bool isDark) {
    final currentStock = productData['currentStock'] ?? 0;
    final minimumStock = productData['minimumStock'] ?? 0;
    final maximumStock = productData['maximumStock'] ?? 0;
    final thresholdLevel = productData['thresholdLevel'] ?? 0;
    final averageUnitPrice = productData['averageUnitPrice']?.toDouble() ?? 0.0;

    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewMetric(
                    'Current Stock',
                    currentStock.toString(),
                    Icons.inventory,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Min Stock',
                    minimumStock.toString(),
                    Icons.warning,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Max Stock',
                    maximumStock.toString(),
                    Icons.storage,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewMetric(
                    'Threshold',
                    thresholdLevel.toString(),
                    Icons.trending_down,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Avg Price',
                    '\$${averageUnitPrice.toStringAsFixed(2)}',
                    Icons.attach_money,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildOverviewMetric(
                    'Stock %',
                    '${((currentStock / maximumStock) * 100).round()}%',
                    Icons.pie_chart,
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

  Widget _buildOverviewMetric(String title, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: maroonReports, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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
    );
  }

  Widget _buildSalesAnalysis(bool isDark) {
    final totalSales = salesHistory.fold<int>(0, (sum, item) => sum + (item['sales'] as int));
    final totalRevenue = salesHistory.fold<double>(0, (sum, item) => sum + (item['revenue'] as double));
    final averageDailySales = totalSales / salesHistory.length;

    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Analysis (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSalesMetric(
                    'Total Sales',
                    '$totalSales units',
                    Icons.shopping_cart,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildSalesMetric(
                    'Total Revenue',
                    '\$${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildSalesMetric(
                    'Daily Average',
                    '${averageDailySales.round()} units',
                    Icons.trending_up,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Daily Sales Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...salesHistory.map((item) => _buildSalesRow(item, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesMetric(String title, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: maroonReports, size: 20),
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
          title,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesRow(Map<String, dynamic> item, bool isDark) {
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
                color: maroonReports,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '\$${item['revenue'].toStringAsFixed(0)}',
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

  Widget _buildOrderHistory(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (orderHistory.isEmpty)
              Center(
                child: Text(
                  'No orders found',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...orderHistory.map((order) => _buildOrderRow(order, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, bool isDark) {
    final createdAt = order['createdAt'] as Timestamp?;
    final deliveryDate = order['deliveryDate'] as Timestamp?;
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order['orderId'].toString().substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(order['status'])),
                ),
                child: Text(
                  order['status'],
                  style: TextStyle(
                    color: _getStatusColor(order['status']),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order['quantity']} units • ${order['supplierName']}',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (createdAt != null)
            Text(
              'Created: ${DateFormat.yMMMd().format(createdAt.toDate())}',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[500],
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSupplierPerformance(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supplier Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...supplierPerformance.map((supplier) => _buildSupplierRow(supplier, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierRow(Map<String, dynamic> supplier, bool isDark) {
    final onTimePercentage = (supplier['onTimeDelivery'] / supplier['totalOrders'] * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            supplier['supplierName'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSupplierMetric(
                  'Orders',
                  supplier['totalOrders'].toString(),
                  isDark,
                ),
              ),
              Expanded(
                child: _buildSupplierMetric(
                  'On-Time',
                  '$onTimePercentage%',
                  isDark,
                ),
              ),
              Expanded(
                child: _buildSupplierMetric(
                  'Rating',
                  '${supplier['averageRating']}★',
                  isDark,
                ),
              ),
              Expanded(
                child: _buildSupplierMetric(
                  'Spent',
                  '\$${supplier['totalSpent'].toStringAsFixed(0)}',
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierMetric(String title, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: maroonReports,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToOrderScreen(),
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Place Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: maroonReports,
                      side: BorderSide(color: maroonReports),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToThresholdManagement(),
                    icon: const Icon(Icons.warning),
                    label: const Text('Manage Threshold'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonReports,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrderScreen() {
    Navigator.of(context).pushNamed(
      '/vendor-quick-order',
      arguments: {
        'productName': widget.productName,
        'suggestedQuantity': 0,
        'vendorEmail': '',
      },
    );
  }

  void _navigateToThresholdManagement() {
    Navigator.of(context).pushNamed('/vendor-threshold-management', arguments: '');
  }
} 