import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auto_reorder_service.dart';
import '../models/order.dart';

const _maroon = Color(0xFF800000);
const _lightCyan = Color(0xFFAFFFFF);

class AutoReorderDashboard extends StatefulWidget {
  final String vendorEmail;

  const AutoReorderDashboard({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<AutoReorderDashboard> createState() => _AutoReorderDashboardState();
}

class _AutoReorderDashboardState extends State<AutoReorderDashboard> {
  bool isLoading = true;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> lowStockItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Load auto-order statistics
      final autoOrderStats = await AutoReorderService.getAutoOrderStats(widget.vendorEmail);
      
      // Load low stock items
      final lowStock = await AutoReorderService.getLowStockItems(widget.vendorEmail);

      setState(() {
        stats = autoOrderStats;
        lowStockItems = lowStock;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading auto-reorder data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : _lightCyan,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_maroon, _maroon.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Reorder Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Intelligent stock monitoring & reordering',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadData,
                icon: Icon(
                  Icons.refresh,
                  color: _maroon,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                // Statistics Cards
                _buildStatsSection(isDark),
                
                const SizedBox(height: 20),
                
                // Low Stock Alerts
                _buildLowStockSection(isDark),
                
                const SizedBox(height: 20),
                
                // Quick Actions
                _buildQuickActionsSection(isDark),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto-Order Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Auto-Orders',
                '${stats['totalAutoOrders'] ?? 0}',
                Icons.shopping_cart,
                Colors.blue,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                '${stats['pendingAutoOrders'] ?? 0}',
                Icons.pending,
                Colors.orange,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${stats['completedAutoOrders'] ?? 0}',
                Icons.check_circle,
                _maroon,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Value',
                '\$${(stats['totalValue'] ?? 0).toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Low Stock Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: lowStockItems.isNotEmpty ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${lowStockItems.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (lowStockItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Text(
                  'All stock levels are healthy',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ...lowStockItems.take(3).map((item) => _buildLowStockItem(item, isDark)),
        
        if (lowStockItems.length > 3)
          TextButton(
            onPressed: () {
              // Navigate to detailed low stock view
              _showLowStockDetails();
            },
            child: Text(
              'View all ${lowStockItems.length} items',
              style: TextStyle(color: _maroon),
            ),
          ),
      ],
    );
  }

  Widget _buildLowStockItem(Map<String, dynamic> item, bool isDark) {
    final stockPercentage = item['stockPercentage'] as double;
    final needsAttention = item['needsAttention'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: needsAttention ? Colors.red : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: needsAttention ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              needsAttention ? Icons.warning : Icons.info,
              color: needsAttention ? Colors.red : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Stock: ${item['currentStock']} / ${item['maximumStock']} (${(stockPercentage * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (item['autoOrderEnabled'] as bool)
            Icon(Icons.auto_awesome, color: _maroon, size: 16)
          else
            Icon(Icons.auto_awesome_outlined, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Monitor Stock',
                Icons.monitor,
                () => _monitorStock(),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Auto-Order Settings',
                Icons.settings,
                () => _showAutoOrderSettings(),
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed, bool isDark) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.white10 : Colors.white,
        foregroundColor: _maroon,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _monitorStock() async {
    try {
      await AutoReorderService.monitorStockAndTriggerOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock monitoring completed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error monitoring stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAutoOrderSettings() {
    // Navigate to auto-order settings screen
    Navigator.of(context).pushNamed('/auto-settings', arguments: widget.vendorEmail);
  }

  void _showLowStockDetails() {
    // Navigate to detailed low stock view
    Navigator.of(context).pushNamed('/below-threshold', arguments: widget.vendorEmail);
  }
} 