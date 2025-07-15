import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auto_reorder_service.dart';
import '../models/order.dart';

const _maroon = Color(0xFF800000);
const _lightCyan = Color(0xFFAFFFFF);

class AutoSettingsScreen extends StatefulWidget {
  final String vendorEmail;

  const AutoSettingsScreen({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<AutoSettingsScreen> createState() => _AutoSettingsScreenState();
}

class _AutoSettingsScreenState extends State<AutoSettingsScreen> {
  List<StockItem> stockItems = [];
  Map<String, double> thresholdValues = {};
  bool isLoading = true;
  bool isSaving = false;

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

      // Initialize threshold values
      for (final item in items) {
        final currentThreshold = item.maximumStock > 0 
            ? (item.minimumStock / item.maximumStock * 100).clamp(1.0, 100.0)
            : 20.0;
        thresholdValues[item.id] = currentThreshold;
      }

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

  Future<void> _saveThresholds() async {
    try {
      setState(() {
        isSaving = true;
      });

      final batch = FirebaseFirestore.instance.batch();

      for (final item in stockItems) {
        final threshold = thresholdValues[item.id] ?? 20.0;
        final minimumStock = (item.maximumStock * threshold / 100).round();

        final docRef = FirebaseFirestore.instance
            .collection('stock_items')
            .doc(item.id);

        batch.update(docRef, {
          'minimumStock': minimumStock,
          'reorderThreshold': threshold / 100,
          'autoOrderEnabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-order settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving thresholds: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Order Settings'),
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : _lightCyan,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Card
              Container(
                margin: const EdgeInsets.all(16),
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
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Configure Auto-Order Thresholds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set minimum stock levels for automatic reordering',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Products List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : stockItems.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildProductsList(isDark),
              ),
              
              // Save Button
              if (stockItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveThresholds,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Saving...'),
                              ],
                            )
                          : const Text(
                              'Save Auto-Order Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
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
              Icons.inventory_outlined,
              color: _maroon,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to your inventory to configure auto-order settings',
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

  Widget _buildProductsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stockItems.length,
      itemBuilder: (context, index) {
        final item = stockItems[index];
        final threshold = thresholdValues[item.id] ?? 20.0;
        final stockPercentage = item.maximumStock > 0 
            ? (item.currentStock / item.maximumStock * 100)
            : 0.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _maroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory,
                        color: _maroon,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '${item.currentStock} / ${item.maximumStock} units',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stockPercentage < threshold ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${stockPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Threshold Slider
                Text(
                  'Minimum Stock Threshold',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: threshold,
                        min: 1.0,
                        max: 100.0,
                        divisions: 99,
                        activeColor: _maroon,
                        inactiveColor: isDark ? Colors.white24 : Colors.grey.shade300,
                        onChanged: (value) {
                          setState(() {
                            thresholdValues[item.id] = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _maroon,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${threshold.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Stock Level Indicator
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: stockPercentage / 100,
                        backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stockPercentage < threshold ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(item.maximumStock * threshold / 100).round()} units',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Supplier Info
                if (item.primarySupplier != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Supplier: ${item.primarySupplier}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
} 