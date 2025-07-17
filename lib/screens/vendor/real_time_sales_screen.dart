import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sales.dart';
import '../../models/order.dart';
import '../../services/sales_service.dart';
import 'invoice_details_screen.dart';
import 'all_invoices_screen.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class RealTimeSalesScreen extends StatefulWidget {
  final String vendorEmail;

  const RealTimeSalesScreen({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<RealTimeSalesScreen> createState() => _RealTimeSalesScreenState();
}

class _RealTimeSalesScreenState extends State<RealTimeSalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<StockItem> availableStockItems = [];
  List<SalesItem> selectedItems = [];
  StockItem? selectedStockItem;
  bool isLoading = true;
  bool isSubmitting = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableStockItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStockItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      final items = await SalesService.getAvailableStockItems(widget.vendorEmail);
      
      setState(() {
        availableStockItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stock items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<StockItem> get filteredStockItems {
    if (searchQuery.isEmpty) {
      return availableStockItems;
    }
    return availableStockItems.where((item) =>
        item.productName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  void _selectStockItem(StockItem item) {
    setState(() {
      selectedStockItem = item;
      _quantityController.text = '1';
      _notesController.text = '';
    });
  }

  void _addToSelectedItems() {
    if (selectedStockItem == null) return;
    
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (quantity > selectedStockItem!.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantity exceeds available stock (${selectedStockItem!.currentStock})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if item already exists in selected items
    final existingIndex = selectedItems.indexWhere((item) => item.productName == selectedStockItem!.productName);
    
    if (existingIndex != -1) {
      // Update existing item
      setState(() {
        selectedItems[existingIndex] = SalesItem(
          id: selectedItems[existingIndex].id,
          productName: selectedStockItem!.productName,
          quantity: quantity,
          unitPrice: selectedStockItem!.averageUnitPrice ?? 0.0,
          totalPrice: (selectedStockItem!.averageUnitPrice ?? 0.0) * quantity,
          soldAt: DateTime.now(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      });
    } else {
      // Add new item
      setState(() {
        selectedItems.add(SalesItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productName: selectedStockItem!.productName,
          quantity: quantity,
          unitPrice: selectedStockItem!.averageUnitPrice ?? 0.0,
          totalPrice: (selectedStockItem!.averageUnitPrice ?? 0.0) * quantity,
          soldAt: DateTime.now(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ));
      });
    }

    // Clear form
    setState(() {
      selectedStockItem = null;
      _quantityController.clear();
      _notesController.clear();
    });
  }

  void _removeFromSelectedItems(int index) {
    setState(() {
      selectedItems.removeAt(index);
    });
  }

  void _editSelectedItem(int index) {
    final item = selectedItems[index];
    final stockItem = availableStockItems.firstWhere((stock) => stock.productName == item.productName);
    
    setState(() {
      selectedStockItem = stockItem;
      _quantityController.text = item.quantity.toString();
      _notesController.text = item.notes ?? '';
    });
  }

  Future<void> _submitSales() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the sales list'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final invoice = await SalesService.createSalesInvoice(
        items: selectedItems,
        vendorEmail: widget.vendorEmail,
        notes: 'Real-time sales entry',
      );

      if (mounted) {
        // Show confirmation dialog with options
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sales Invoice Created!'),
            content: Text('The stock has been updated. What would you like to do next?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => InvoiceDetailsScreen(invoice: invoice),
                  ));
                },
                child: const Text('View Invoice'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to dashboard
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating sales invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Sales'),
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
            icon: const Icon(Icons.history),
            onPressed: () => _showDrawer(context),
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(maroon),
                ),
              )
            : Column(
                children: [
                  // Search Bar
                  _buildSearchBar(isDark),
                  // Search Results
                  if (searchQuery.isNotEmpty) _buildSearchResults(isDark),
                  // Selected Item Form
                  if (selectedStockItem != null) _buildItemForm(isDark),
                  // Selected Items List
                  Expanded(
                    child: _buildSelectedItemsList(isDark),
                  ),
                  // Submit Button
                  _buildSubmitButton(isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search available stock items...',
          prefixIcon: const Icon(Icons.search, color: maroon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: maroon),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: maroon, width: 2),
          ),
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredStockItems.length,
        itemBuilder: (context, index) {
          final item = filteredStockItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isDark ? Colors.white10 : Colors.white,
            child: ListTile(
              title: Text(
                item.productName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
                             subtitle: Text(
                 'Price: UGX${(item.averageUnitPrice ?? 0.0).toStringAsFixed(2)}',
                 style: TextStyle(
                   color: isDark ? Colors.white70 : Colors.grey[600],
                 ),
               ),
              trailing: Text(
                'Stock: ${item.currentStock}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              onTap: () {
                _selectStockItem(item);
                setState(() {
                  searchQuery = ''; // Clear search query after selection
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemForm(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product: ${selectedStockItem!.productName}',
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
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Available: ${selectedStockItem!.currentStock}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addToSelectedItems,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedStockItem = null;
                      _quantityController.clear();
                      _notesController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: maroon,
                    side: BorderSide(color: maroon),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemsList(bool isDark) {
    if (selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items selected',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search and add items to create your sales invoice',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.list, color: maroon),
              const SizedBox(width: 8),
              Text(
                'Selected Items (${selectedItems.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: selectedItems.length,
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isDark ? Colors.white10 : Colors.white,
                child: ListTile(
                  title: Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${item.quantity}'),
                      Text('Price: UGX${item.unitPrice.toStringAsFixed(2)}'),
                      Text('Total: UGX${item.totalPrice.toStringAsFixed(2)}'),
                      if (item.notes != null) Text('Notes: ${item.notes}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: maroon),
                        onPressed: () => _editSelectedItem(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFromSelectedItems(index),
                      ),
                    ],
                  ),
                  onTap: () => _editSelectedItem(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isSubmitting ? null : _submitSales,
          icon: isSubmitting 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(isSubmitting ? 'Submitting...' : 'Submit All Sales'),
          style: ElevatedButton.styleFrom(
            backgroundColor: maroon,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Sales History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Last Invoice',
                  subtitle: 'View the most recent sales invoice',
                  onTap: () => _viewLastInvoice(context),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'All Invoices',
                  subtitle: 'Browse all sales invoices',
                  onTap: () => _viewAllInvoices(context),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildDrawerItem(
                  context,
                  icon: Icons.filter_list,
                  title: 'Filter by Date',
                  subtitle: 'Filter invoices by date range',
                  onTap: () => _filterInvoicesByDate(context),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: maroon.withOpacity(0.2),
          child: Icon(icon, color: maroon),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _viewLastInvoice(BuildContext context) async {
    Navigator.pop(context);
    try {
      final latestInvoice = await SalesService.getLatestInvoice(widget.vendorEmail);
      if (latestInvoice != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => InvoiceDetailsScreen(invoice: latestInvoice),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No invoices found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading last invoice: $e')),
        );
      }
    }
  }

  void _viewAllInvoices(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AllInvoicesScreen(vendorEmail: widget.vendorEmail),
    ));
  }

  void _filterInvoicesByDate(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AllInvoicesScreen(vendorEmail: widget.vendorEmail),
    ));
  }
} 