import 'package:flutter/material.dart';  
import '../../models/order.dart';
import '../../mock_data/mock_orders.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class StockManagementScreen extends StatelessWidget {
  // Remove const constructor to allow hot reload after class structure changes
  StockManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: mockStockItems.length,
          itemBuilder: (context, index) {
            final stockItem = mockStockItems[index];
            return _buildStockCard(context, stockItem, isDark, index);
          },
        ),
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, StockItem stockItem, bool isDark, int index) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: stockItem.isLowStock 
              ? maroon.withOpacity(0.2) 
              : Colors.grey.shade200,
          child: Icon(
            Icons.inventory, 
            color: stockItem.isLowStock ? maroon : Colors.grey
          ),
        ),
        title: Text(
          stockItem.productName, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock:  {stockItem.currentStock} /  {stockItem.maximumStock}'),
            if (stockItem.isLowStock)
              Text(
                'Low Stock Alert!',
                style: TextStyle(
                  color: maroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stockItem.autoOrderEnabled)
              Icon(Icons.auto_awesome, color: maroon, size: 20),
            const SizedBox(width: 8),
            Icon(Icons.expand_more, color: maroon),
          ],
        ),
        children: [
          _buildStockDetails(context, stockItem, isDark, index),
        ],
      ),
    );
  }

  Widget _buildStockDetails(BuildContext context, StockItem stockItem, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Overview
          _buildStockOverview(stockItem, isDark),
          const SizedBox(height: 16),
          
          // Supplier Information
          if (stockItem.primarySupplier != null)
            _buildSupplierInfo(stockItem, isDark),
          
          const SizedBox(height: 16),
          
          // Delivery History
          _buildDeliveryHistory(stockItem, isDark),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          _buildActionButtons(context, stockItem, isDark, index),
        ],
      ),
    );
  }

  Widget _buildStockOverview(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: maroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Current Stock',
                  '${stockItem.currentStock}',
                  Icons.inventory,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Min Stock',
                  '${stockItem.minimumStock}',
                  Icons.warning,
                  isDark,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Max Stock',
                  '${stockItem.maximumStock}',
                  Icons.storage,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stockItem.stockPercentage,
            backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              stockItem.isLowStock ? maroon : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(stockItem.stockPercentage * 100).toStringAsFixed(1)}% of max capacity',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfo(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Supplier',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Icon(Icons.business, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockItem.primarySupplier!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      stockItem.primarySupplierEmail!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (stockItem.averageUnitPrice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Avg. Unit Price: \$${stockItem.averageUnitPrice!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryHistory(StockItem stockItem, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${stockItem.totalDeliveries} deliveries',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stockItem.firstDeliveryDate != null) ...[
            Text(
              'First Delivery: ${_formatDate(stockItem.firstDeliveryDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (stockItem.lastDeliveryDate != null) ...[
            Text(
              'Last Delivery: ${_formatDate(stockItem.lastDeliveryDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Total Delivered: ${stockItem.totalDelivered} units',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (stockItem.deliveryHistory.isNotEmpty) ...[
            Text(
              'Recent Deliveries:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...stockItem.deliveryHistory
                .take(3)
                .map((record) => _buildDeliveryRecord(record, isDark))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryRecord(DeliveryRecord record, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.quantity} units from ${record.supplierName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(record.deliveryDate),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (record.unitPrice != null)
            Text(
              '\$${record.unitPrice!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, StockItem stockItem, bool isDark, int index) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showEditStockDialog(context, stockItem, index);
            },
            icon: Icon(Icons.edit, size: 16),
            label: const Text('Update Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditStockDialog(BuildContext context, StockItem stockItem, int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter number of goods purchased'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroon,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final qty = int.tryParse(controller.text) ?? 0;
              if (qty > 0 && qty <= stockItem.currentStock) {
                mockStockItems[index] = StockItem(
                  id: stockItem.id,
                  productName: stockItem.productName,
                  currentStock: stockItem.currentStock - qty,
                  minimumStock: stockItem.minimumStock,
                  maximumStock: stockItem.maximumStock,
                  deliveryHistory: stockItem.deliveryHistory,
                  primarySupplier: stockItem.primarySupplier,
                  primarySupplierEmail: stockItem.primarySupplierEmail,
                  firstDeliveryDate: stockItem.firstDeliveryDate,
                  lastDeliveryDate: stockItem.lastDeliveryDate,
                  autoOrderEnabled: stockItem.autoOrderEnabled,
                  averageUnitPrice: stockItem.averageUnitPrice,
                );
                (context as Element).markNeedsBuild();
              }
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: maroon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 