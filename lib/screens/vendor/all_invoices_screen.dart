import 'package:flutter/material.dart';
import '../../models/sales.dart';
import '../../services/sales_service.dart';
import 'invoice_details_screen.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class AllInvoicesScreen extends StatefulWidget {
  final String vendorEmail;

  const AllInvoicesScreen({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<AllInvoicesScreen> createState() => _AllInvoicesScreenState();
}

class _AllInvoicesScreenState extends State<AllInvoicesScreen> {
  List<SalesInvoice> invoices = [];
  List<SalesInvoice> filteredInvoices = [];
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      setState(() {
        isLoading = true;
      });

      final loadedInvoices = await SalesService.getInvoicesForVendor(widget.vendorEmail);
      
      setState(() {
        invoices = loadedInvoices;
        filteredInvoices = loadedInvoices;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterInvoices() {
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        // Filter by search query
        if (searchQuery.isNotEmpty) {
          final matchesSearch = invoice.invoiceNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
              invoice.items.any((item) => item.productName.toLowerCase().contains(searchQuery.toLowerCase()));
          if (!matchesSearch) return false;
        }

        // Filter by date range
        if (startDate != null && invoice.createdAt.isBefore(startDate!)) {
          return false;
        }
        if (endDate != null && invoice.createdAt.isAfter(endDate!)) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null 
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _filterInvoices();
    }
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      startDate = null;
      endDate = null;
      filteredInvoices = invoices;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Invoices'),
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
            icon: const Icon(Icons.filter_list),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: Column(
          children: [
            _buildSearchAndFilters(isDark),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(maroon),
                      ),
                    )
                  : filteredInvoices.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildInvoicesList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
              _filterInvoices();
            },
            decoration: InputDecoration(
              hintText: 'Search invoices...',
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
          if (startDate != null || endDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: maroon.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: maroon, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${startDate != null ? _formatDate(startDate!) : 'Any'} - ${endDate != null ? _formatDate(endDate!) : 'Any'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Icon(Icons.close, color: maroon, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or date filters',
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

  Widget _buildInvoicesList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredInvoices.length,
      itemBuilder: (context, index) {
        final invoice = filteredInvoices[index];
        return _buildInvoiceCard(invoice, isDark);
      },
    );
  }

  Widget _buildInvoiceCard(SalesInvoice invoice, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.white10 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: maroon.withOpacity(0.2),
          child: Icon(Icons.receipt, color: maroon),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(invoice.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${invoice.items.length} items • ${invoice.items.fold(0, (sum, item) => sum + item.quantity)} total qty',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'UGX${invoice.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                invoice.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => InvoiceDetailsScreen(invoice: invoice),
          ));
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 