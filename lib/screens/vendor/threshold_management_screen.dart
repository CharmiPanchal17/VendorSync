import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order.dart';
import '../../services/notification_service.dart';

const maroonThreshold = Color(0xFF800000);
const lightCyanThreshold = Color(0xFFAFFFFF);

class ThresholdManagementScreen extends StatefulWidget {
  final String vendorEmail;
  
  const ThresholdManagementScreen({super.key, required this.vendorEmail});

  @override
  State<ThresholdManagementScreen> createState() => _ThresholdManagementScreenState();
}

class _ThresholdManagementScreenState extends State<ThresholdManagementScreen> {
  List<StockItem> stockItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      setState(() { isLoading = true; });
      
      final stockSnapshot = await FirebaseFirestore.instance
          .collection('stock_items')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .get();

      if (stockSnapshot.docs.isNotEmpty) {
        final loadedStockItems = stockSnapshot.docs.map((doc) {
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
            vendorEmail: widget.vendorEmail,
            thresholdLevel: data['thresholdLevel'] ?? 0,
            thresholdNotificationsEnabled: data['thresholdNotificationsEnabled'] ?? true,
            lastThresholdAlert: data['lastThresholdAlert'] != null 
                ? (data['lastThresholdAlert'] as Timestamp).toDate() 
                : null,
            suggestedOrderQuantity: data['suggestedOrderQuantity'] ?? 0,
          );
        }).toList();

        setState(() {
          stockItems = loadedStockItems;
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print('Error loading stock data: $e');
      setState(() { isLoading = false; });
    }
  }

  List<DeliveryRecord> _parseDeliveryHistory(List<dynamic> history) {
    return history.map((item) => DeliveryRecord(
      id: item['id'] ?? '',
      orderId: item['orderId'] ?? '',
      productName: item['productName'] ?? '',
      quantity: item['quantity'] ?? 0,
      supplierName: item['supplierName'] ?? '',
      supplierEmail: item['supplierEmail'] ?? '',
      deliveryDate: (item['deliveryDate'] as Timestamp).toDate(),
      unitPrice: item['unitPrice']?.toDouble(),
      notes: item['notes'],
      status: item['status'] ?? '',
      vendorEmail: widget.vendorEmail,
    )).toList();
  }

  Future<void> _updateThreshold(StockItem item, int newThreshold, bool notificationsEnabled) async {
    try {
      await FirebaseFirestore.instance
          .collection('stock_items')
          .doc(item.id)
          .update({
        'thresholdLevel': newThreshold,
        'thresholdNotificationsEnabled': notificationsEnabled,
        'suggestedOrderQuantity': item.calculateSuggestedOrderQuantity(),
      });

      // Also update the product_inventory collection for this product/vendor
      final inventoryQuery = await FirebaseFirestore.instance
          .collection('product_inventory')
          .where('productName', isEqualTo: item.productName)
          .where('vendorEmail', isEqualTo: item.vendorEmail)
          .limit(1)
          .get();
      if (inventoryQuery.docs.isNotEmpty) {
        await inventoryQuery.docs.first.reference.update({
          'lowStockThreshold': newThreshold,
        });
      }

      // Reload data
      await _loadStockData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Threshold updated for ${item.productName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating threshold: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threshold Management'),
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
                      : [maroonThreshold, maroonThreshold.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyanThreshold,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : stockItems.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: stockItems.length,
                    itemBuilder: (context, index) {
                      final item = stockItems[index];
                      return _buildStockItemCard(item, isDark);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to your inventory to set threshold levels.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white38 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemCard(StockItem item, bool isDark) {
    final thresholdStatus = item.thresholdStatus;
    Color statusColor;
    IconData statusIcon;
    
    switch (thresholdStatus) {
      case ThresholdStatus.critical:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case ThresholdStatus.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber;
        break;
      case ThresholdStatus.info:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Current Stock: ${item.currentStock}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildThresholdStatusChip(thresholdStatus, isDark),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock Level Indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: item.stockPercentage.clamp(0.0, 1.0),
                        backgroundColor: isDark ? Colors.white24 : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(item.stockPercentage * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Max: ${item.maximumStock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Threshold Settings
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Threshold Level',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.thresholdLevel}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Switch(
                      value: item.thresholdNotificationsEnabled,
                      onChanged: (value) => _updateThreshold(
                        item,
                        item.thresholdLevel,
                        value,
                      ),
                      activeColor: maroonThreshold,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showThresholdDialog(item, isDark),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Threshold'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: maroonThreshold,
                      side: BorderSide(color: maroonThreshold),
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

  Widget _buildThresholdStatusChip(ThresholdStatus status, bool isDark) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case ThresholdStatus.critical:
        chipColor = Colors.red;
        statusText = 'Critical';
        break;
      case ThresholdStatus.warning:
        chipColor = Colors.orange;
        statusText = 'Warning';
        break;
      case ThresholdStatus.info:
        chipColor = Colors.blue;
        statusText = 'Low';
        break;
      default:
        chipColor = Colors.green;
        statusText = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showThresholdDialog(StockItem item, bool isDark) {
    final thresholdController = TextEditingController(
      text: item.thresholdLevel.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Set Threshold for ${item.productName}',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Stock: ${item.currentStock}\nMinimum Stock: ${item.minimumStock}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: thresholdController,
              decoration: InputDecoration(
                labelText: 'Threshold Level',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: maroonThreshold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newThreshold = int.tryParse(thresholdController.text) ?? 0;
              _updateThreshold(item, newThreshold, item.thresholdNotificationsEnabled);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonThreshold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


} 