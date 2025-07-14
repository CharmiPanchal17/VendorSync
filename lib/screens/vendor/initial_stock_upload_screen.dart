import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import '../../services/sales_service.dart';
import 'dart:io';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class InitialStockUploadScreen extends StatefulWidget {
  final String vendorEmail;
  const InitialStockUploadScreen({super.key, required this.vendorEmail});

  @override
  State<InitialStockUploadScreen> createState() => _InitialStockUploadScreenState();
}

class _InitialStockUploadScreenState extends State<InitialStockUploadScreen> {
  List<Map<String, dynamic>> parsedItems = [];
  bool isLoading = false;
  bool isUploading = false;
  String? selectedFileName;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Initial Stock'),
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
              'Upload Initial Stock CSV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'CSV columns required: productName, initialQuantity, unitPrice, supplierName, notes (optional)',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
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
              item['productName'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantity: ${item['initialQuantity']}'),
                Text('Unit Price: UGX${item['unitPrice']}'),
                if (item['supplierName'] != null) Text('Supplier: ${item['supplierName']}'),
                if (item['notes'] != null) Text('Notes: ${item['notes']}'),
              ],
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
        onPressed: isUploading ? null : _submitStock,
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
        label: Text(isUploading ? 'Processing...' : 'Submit Initial Stock'),
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
        allowedExtensions: ['csv', 'xlsx'],
      );
      if (result != null) {
        final file = result.files.first;
        setState(() {
          selectedFileName = file.name;
        });
        if (file.extension == 'csv') {
          await _parseCSVFile(file);
        } else if (file.extension == 'xlsx') {
          await _parseXLSXFile(file);
        } else {
          setState(() {
            errorMessage = 'Unsupported file type.';
          });
        }
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
      String? content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
      if (content == null || content.isEmpty) {
        setState(() {
          errorMessage = 'CSV file is empty or unreadable.';
        });
        return;
      }
      final rows = const CsvToListConverter(eol: '\n').convert(content, eol: '\n');
      if (rows.isEmpty) {
        setState(() {
          errorMessage = 'CSV file is empty.';
        });
        return;
      }
      final header = rows.first.map((e) => e.toString().trim()).toList();
      final List<Map<String, dynamic>> items = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;
        final productName = row[header.indexOf('productName')].toString().trim();
        final initialQuantity = int.tryParse(row[header.indexOf('initialQuantity')].toString()) ?? 0;
        final unitPrice = header.contains('unitPrice') ? double.tryParse(row[header.indexOf('unitPrice')].toString()) ?? 0.0 : 0.0;
        final supplierName = header.contains('supplierName') ? row[header.indexOf('supplierName')].toString() : null;
        final notes = header.contains('notes') ? row[header.indexOf('notes')].toString() : null;
        if (productName.isNotEmpty && initialQuantity > 0) {
          items.add({
            'productName': productName,
            'initialQuantity': initialQuantity,
            'unitPrice': unitPrice,
            'supplierName': supplierName,
            'notes': notes,
          });
        }
      }
      setState(() {
        parsedItems = items;
      });
      if (items.isEmpty) {
        setState(() {
          errorMessage = 'No valid items found in the file. Please check the format.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error parsing file: $e';
      });
    }
  }

  Future<void> _parseXLSXFile(PlatformFile file) async {
    try {
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        setState(() {
          errorMessage = 'File is empty or unreadable.';
        });
        return;
      }
      final excel = ex.Excel.decodeBytes(bytes);
      // Find the first non-empty sheet (null-safe)
      ex.Sheet? sheet;
      try {
        sheet = excel.tables.values.firstWhere(
          (s) => s.maxRows > 0 && s.rows.any((row) => row.any((cell) => cell != null && cell.value.toString().trim().isNotEmpty)),
        );
      } catch (_) {
        sheet = null;
      }
      if (sheet == null) {
        setState(() {
          errorMessage = 'Spreadsheet is empty.';
        });
        return;
      }
      // Skip blank rows at the top
      int headerRowIdx = 0;
      while (headerRowIdx < sheet.rows.length &&
        sheet.rows[headerRowIdx].every((cell) => cell == null || cell.value.toString().trim().isEmpty)) {
        headerRowIdx++;
      }
      if (headerRowIdx >= sheet.rows.length) {
        setState(() {
          errorMessage = 'No header row found in spreadsheet.';
        });
        return;
      }
      final header = sheet.rows[headerRowIdx].map((e) => e?.value.toString().trim() ?? '').toList();
      final List<Map<String, dynamic>> items = [];
      for (int i = headerRowIdx + 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length < 2) continue;
        final productName = row.length > header.indexOf('productName') && row[header.indexOf('productName')] != null ? row[header.indexOf('productName')]!.value.toString().trim() : '';
        final initialQuantity = header.contains('initialQuantity') && row.length > header.indexOf('initialQuantity') ? int.tryParse(row[header.indexOf('initialQuantity')]?.value.toString() ?? '') ?? 0 : 0;
        final unitPrice = header.contains('unitPrice') && row.length > header.indexOf('unitPrice') ? double.tryParse(row[header.indexOf('unitPrice')]?.value.toString() ?? '') ?? 0.0 : 0.0;
        final supplierName = header.contains('supplierName') && row.length > header.indexOf('supplierName') ? row[header.indexOf('supplierName')]?.value.toString() : null;
        final notes = header.contains('notes') && row.length > header.indexOf('notes') ? row[header.indexOf('notes')]?.value.toString() : null;
        if (productName.isNotEmpty && initialQuantity > 0) {
          items.add({
            'productName': productName,
            'initialQuantity': initialQuantity,
            'unitPrice': unitPrice,
            'supplierName': supplierName,
            'notes': notes,
          });
        }
      }
      setState(() {
        parsedItems = items;
      });
      if (items.isEmpty) {
        setState(() {
          errorMessage = 'No valid items found in the spreadsheet. Please check the format.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error parsing spreadsheet: $e';
      });
    }
  }

  Future<void> _submitStock() async {
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
      // Save each item to Firestore as a stock item
      for (final item in parsedItems) {
        await SalesService.addInitialStockItem(
          vendorEmail: widget.vendorEmail,
          productName: item['productName'],
          initialQuantity: item['initialQuantity'],
          unitPrice: item['unitPrice'],
          supplierName: item['supplierName'],
          notes: item['notes'],
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Initial stock uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error uploading initial stock: $e';
        });
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
} 