import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import '../../services/sales_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'sales_data_export_stub.dart'
    if (dart.library.html) 'sales_data_export_web.dart' as sales_export;

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class SalesDataUploadScreen extends StatefulWidget {
  final String vendorEmail;
  const SalesDataUploadScreen({super.key, required this.vendorEmail});

  @override
  State<SalesDataUploadScreen> createState() => _SalesDataUploadScreenState();
}

class _SalesDataUploadScreenState extends State<SalesDataUploadScreen> {
  List<Map<String, dynamic>> parsedSales = [];
  bool isLoading = false;
  bool isUploading = false;
  String? selectedFileName;
  String? errorMessage;
  String? selectedPeriod;
  Map<String, dynamic>? analysisResult;

  final List<String> periods = ['Week', 'Month', 'Year'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Sales Data'),
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
                const SizedBox(height: 16),
                _buildPeriodDropdown(isDark),
                const SizedBox(height: 16),
                _buildFilePicker(isDark),
                const SizedBox(height: 24),
                if (errorMessage != null) _buildErrorMessage(isDark),
                if (parsedSales.isNotEmpty) ...[
                  _buildPreviewHeader(isDark),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildPreviewList(isDark),
                  ),
                  const SizedBox(height: 16),
                  _buildSubmitButton(isDark),
                ],
                if (analysisResult != null) ...[
                  const SizedBox(height: 24),
                  _buildAnalysisReport(isDark),
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
              'Upload Sales Data CSV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'CSV columns required: productName, quantity, unitPrice, soldAt (YYYY-MM-DD), notes (optional)',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedPeriod,
      decoration: InputDecoration(
        labelText: 'Select Period',
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: periods.map((period) {
        return DropdownMenuItem<String>(
          value: period,
          child: Text(period),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedPeriod = value;
        });
      },
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
                        parsedSales.clear();
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
          'Preview (${parsedSales.length} items)',
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
      itemCount: parsedSales.length,
      itemBuilder: (context, index) {
        final item = parsedSales[index];
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
                Text('Quantity: ${item['quantity']}'),
                Text('Unit Price: UGX${item['unitPrice']}'),
                Text('Sold At: ${item['soldAt']}'),
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
        onPressed: isUploading ? null : _analyzeSales,
        icon: isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.analytics),
        label: Text(isUploading ? 'Analyzing...' : 'Analyze Sales Data'),
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
        final quantity = int.tryParse(row[header.indexOf('quantity')].toString()) ?? 0;
        final unitPrice = header.contains('unitPrice') ? double.tryParse(row[header.indexOf('unitPrice')].toString()) ?? 0.0 : 0.0;
        final soldAt = header.contains('soldAt') ? row[header.indexOf('soldAt')].toString() : null;
        final notes = header.contains('notes') ? row[header.indexOf('notes')].toString() : null;
        if (productName.isNotEmpty && quantity > 0 && soldAt != null && soldAt.isNotEmpty) {
          items.add({
            'productName': productName,
            'quantity': quantity,
            'unitPrice': unitPrice,
            'soldAt': soldAt,
            'notes': notes,
          });
        }
      }
      setState(() {
        parsedSales = items;
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
        final quantity = header.contains('quantity') && row.length > header.indexOf('quantity') ? int.tryParse(row[header.indexOf('quantity')]?.value.toString() ?? '') ?? 0 : 0;
        final unitPrice = header.contains('unitPrice') && row.length > header.indexOf('unitPrice') ? double.tryParse(row[header.indexOf('unitPrice')]?.value.toString() ?? '') ?? 0.0 : 0.0;
        final soldAt = header.contains('soldAt') && row.length > header.indexOf('soldAt') ? row[header.indexOf('soldAt')]?.value.toString() : null;
        final notes = header.contains('notes') && row.length > header.indexOf('notes') ? row[header.indexOf('notes')]?.value.toString() : null;
        if (productName.isNotEmpty && quantity > 0 && soldAt != null && soldAt.isNotEmpty) {
          items.add({
            'productName': productName,
            'quantity': quantity,
            'unitPrice': unitPrice,
            'soldAt': soldAt,
            'notes': notes,
          });
        }
      }
      setState(() {
        parsedSales = items;
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

  Future<void> _analyzeSales() async {
    if (parsedSales.isEmpty || selectedPeriod == null) {
      setState(() {
        errorMessage = 'Please select a period and upload a valid sales CSV.';
      });
      return;
    }
    setState(() {
      isUploading = true;
      errorMessage = null;
    });
    try {
      // Call analysis service (to be implemented in SalesService)
      final result = await SalesService.analyzeSalesData(
        vendorEmail: widget.vendorEmail,
        sales: parsedSales,
        period: selectedPeriod!,
      );
      setState(() {
        analysisResult = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error analyzing sales data: $e';
      });
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Widget _buildAnalysisReport(bool isDark) {
    final report = analysisResult ?? {};
    final products = report['products'] as List<Map<String, dynamic>>? ?? [];
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: maroon)),
                  Text('Initial Stock: ${p['initialStock']}'),
                  Text('Sold: ${p['sold']}'),
                  Text('Remaining: ${p['remaining']}'),
                  Text('Sales Rate: ${p['salesRate']} per $selectedPeriod'),
                  Text('Reorder Suggestion: ${p['reorderSuggestion']}'),
                  if (p['trend'] != null) Text('Trend: ${p['trend']}'),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export as CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _exportAnalysisCSV(products),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export as PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _exportAnalysisPDF(products),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAnalysisCSV(List<Map<String, dynamic>> products) async {
    final headers = [
      'Product Name',
      'Initial Stock',
      'Sold',
      'Remaining',
      'Sales Rate',
      'Trend',
      'Reorder Suggestion',
    ];
    final dataRows = products.map((p) => [
      p['productName'] ?? '',
      '${p['initialStock']}',
      '${p['sold']}',
      '${p['remaining']}',
      '${p['salesRate']}',
      p['trend'] ?? '',
      p['reorderSuggestion'] ?? '',
    ]).toList();
    final csvData = const ListToCsvConverter().convert([headers, ...dataRows]);
    if (kIsWeb) {
      await sales_export.exportCSV(csvData);
    } else {
      await Printing.sharePdf(bytes: Uint8List.fromList(csvData.codeUnits), filename: 'sales_analysis_report.csv');
    }
  }

  Future<void> _exportAnalysisPDF(List<Map<String, dynamic>> products) async {
    final pdf = pw.Document();
    final headers = [
      'Product Name',
      'Initial Stock',
      'Sold',
      'Remaining',
      'Sales Rate',
      'Trend',
      'Reorder Suggestion',
    ];
    final dataRows = products.map((p) => [
      p['productName'] ?? '',
      '${p['initialStock']}',
      '${p['sold']}',
      '${p['remaining']}',
      '${p['salesRate']}',
      p['trend'] ?? '',
      p['reorderSuggestion'] ?? '',
    ]).toList();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Sales Analysis Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: headers,
            data: dataRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: pw.BoxDecoration(),
            headerHeight: 24,
            cellHeight: 20,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellDecoration: (index, data, rowNum) => pw.BoxDecoration(),
          ),
        ],
      ),
    );
    if (kIsWeb) {
      final bytes = await pdf.save();
      await sales_export.exportPDF(bytes);
    } else {
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    }
  }
} 