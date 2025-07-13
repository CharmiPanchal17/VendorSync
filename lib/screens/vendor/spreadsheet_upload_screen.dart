import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../models/sales.dart';
import '../../services/sales_service.dart';
import 'package:csv/csv.dart';
import 'report_screen.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class SpreadsheetUploadScreen extends StatefulWidget {
  final String vendorEmail;

  const SpreadsheetUploadScreen({
    super.key,
    required this.vendorEmail,
  });

  @override
  State<SpreadsheetUploadScreen> createState() => _SpreadsheetUploadScreenState();
}

class _SpreadsheetUploadScreenState extends State<SpreadsheetUploadScreen> {
  List<SalesItem> parsedItems = [];
  bool isLoading = false;
  bool isUploading = false;
  String? selectedFileName;
  String? errorMessage;

  Future<bool> _onWillPop() async {
    if (parsedItems.isNotEmpty && !isUploading) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Sales'),
          content: const Text('You have uploaded sales that are not yet submitted. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload Spreadsheet'),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInstructions(isDark),
                  const SizedBox(height: 24),
                  _buildFilePicker(isDark),
                  const SizedBox(height: 24),
                  if (errorMessage != null) _buildErrorMessage(isDark),
                  if (parsedItems.isNotEmpty) ...[
                    _buildPreviewHeader(isDark),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: _buildPreviewList(isDark),
                    ),
                    const SizedBox(height: 16),
                    _buildSubmitButton(isDark),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Sales Spreadsheet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload a CSV file with the following columns:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• productName (required)\n• quantity (required)\n• unitPrice (optional)\n• notes (optional)',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: maroon.withOpacity(0.3)),
              ),
              child: Text(
                'Note: Only products with available stock will be processed.',
                style: TextStyle(
                  fontSize: 12,
                  color: maroon,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(bool isDark) {
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (selectedFileName != null) ...[
              Row(
                children: [
                  Icon(Icons.file_present, color: maroon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedFileName!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        selectedFileName = null;
                        parsedItems.clear();
                        errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _pickFile,
                icon: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isLoading ? 'Processing...' : 'Select CSV File'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(bool isDark) {
    return Row(
      children: [
        Icon(Icons.preview, color: maroon),
        const SizedBox(width: 8),
        Text(
          'Preview (${parsedItems.length} items)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewList(bool isDark) {
    return ListView.builder(
      itemCount: parsedItems.length,
      itemBuilder: (context, index) {
        final item = parsedItems[index];
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
                if (item.notes != null) Text('Notes: ${item.notes}'),
              ],
            ),
            trailing: Text(
              'Total: UGX${item.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isUploading ? null : _submitSales,
        icon: isUploading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send),
        label: Text(isUploading ? 'Processing...' : 'Submit All Sales'),
        style: ElevatedButton.styleFrom(
          backgroundColor: maroon,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          selectedFileName = file.name;
        });

        // Read and parse the CSV file
        await _parseCSVFile(file);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error picking file: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _parseCSVFile(PlatformFile file) async {
    try {
      print('[CSV] Parsing file: ${file.name}');
      final content = String.fromCharCodes(file.bytes!);
      print('[CSV] Raw content:');
      print(content);
      final rows = const CsvToListConverter(eol: '\n').convert(content, eol: '\n');
      if (rows.isEmpty) {
        setState(() {
          errorMessage = 'CSV file is empty.';
        });
        print('[CSV][ERROR] File is empty.');
        return;
      }
      final header = rows.first.map((e) => e.toString().trim()).toList();
      print('[CSV] Header: $header');
      final List<SalesItem> items = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        print('[CSV] Row $i: $row');
        if (row.length < 2) continue;
        final productName = row[header.indexOf('productName')].toString().trim();
        final quantity = int.tryParse(row[header.indexOf('quantity')].toString()) ?? 0;
        final unitPrice = header.contains('unitPrice') ? double.tryParse(row[header.indexOf('unitPrice')].toString()) ?? 0.0 : 0.0;
        final notes = header.contains('notes') ? row[header.indexOf('notes')].toString() : null;
        print('[CSV] Parsed: productName=$productName, quantity=$quantity, unitPrice=$unitPrice, notes=$notes');
        if (productName.isNotEmpty && quantity > 0) {
          items.add(SalesItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productName: productName,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: unitPrice * quantity,
            soldAt: DateTime.now(),
            notes: notes,
          ));
        }
      }
      setState(() {
        parsedItems = items;
      });
      print('[CSV] Parsed items: $parsedItems');
      if (items.isEmpty) {
        setState(() {
          errorMessage = 'No valid items found in the file. Please check the format.';
        });
        print('[CSV][ERROR] No valid items found.');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error parsing file: $e';
      });
      print('[CSV][EXCEPTION] $e');
    }
  }

  Future<void> _submitSales() async {
    if (parsedItems.isEmpty) {
      setState(() {
        errorMessage = 'No items to submit';
      });
      return;
    }

    setState(() {
      isUploading = true;
      errorMessage = null;
    });

    try {
      // Filter parsedItems to only those in available stock
      final availableStock = await SalesService.getAvailableStockItems(widget.vendorEmail);
      final availableNames = availableStock.map((s) => s.productName.toLowerCase()).toSet();
      final filteredItems = parsedItems.where((item) => availableNames.contains(item.productName.toLowerCase())).toList();
      final ignoredCount = parsedItems.length - filteredItems.length;

      if (filteredItems.isEmpty) {
        setState(() {
          errorMessage = 'No valid items to submit. None of the products exist in your stock.';
        });
        return;
      }

      final invoice = await SalesService.createSalesInvoice(
        items: filteredItems,
        vendorEmail: widget.vendorEmail,
        notes: 'Bulk upload from spreadsheet: $selectedFileName',
      );

      if (mounted) {
        String msg = 'Sales invoice created successfully! Invoice: ${invoice.invoiceNumber}';
        if (ignoredCount > 0) {
          msg += '\n$ignoredCount item(s) were ignored because they do not exist in your stock.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh report if open
        ReportScreen.refreshReport(context);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error creating sales invoice: $e';
        });
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
} 