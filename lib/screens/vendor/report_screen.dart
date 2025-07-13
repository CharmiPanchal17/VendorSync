import 'package:flutter/material.dart';
import '../../services/sales_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
// Add this import only for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

const maroonVendor = Color(0xFF800000);

class ReportScreen extends StatefulWidget {
  final String vendorEmail;
  static void refreshReport(BuildContext context) {
    final state = context.findAncestorStateOfType<_ReportScreenState>();
    state?._loadReport();
  }
  const ReportScreen({super.key, required this.vendorEmail});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Map<String, dynamic>> report = [];
  bool isLoading = true;
  DateTimeRange? selectedRange;
  String productQuery = '';
  List<Map<String, dynamic>> get filteredReport {
    if (productQuery.isEmpty) return report;
    return report.where((item) => (item['productName'] ?? '').toString().toLowerCase().contains(productQuery.toLowerCase())).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() { isLoading = true; });
    // Only pass vendorEmail, remove startDate/endDate
    final data = await SalesService.generateStockReport(widget.vendorEmail);
    setState(() {
      report = data;
      isLoading = false;
    });
  }

  void _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: selectedRange,
    );
    if (picked != null) {
      setState(() { selectedRange = picked; });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Report'),
        backgroundColor: maroonVendor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickDateRange,
                              icon: const Icon(Icons.date_range),
                              label: Text(selectedRange == null
                                  ? 'Select Date Range'
                                  : '${selectedRange!.start.toLocal().toString().split(' ')[0]} - ${selectedRange!.end.toLocal().toString().split(' ')[0]}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: maroonVendor,
                                side: BorderSide(color: maroonVendor),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search product...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: maroonVendor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                ),
                                onChanged: (val) => setState(() => productQuery = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: filteredReport.isEmpty ? null : _exportAsPDF,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Export as PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maroonVendor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: filteredReport.isEmpty ? null : _exportAsCSV,
                              icon: const Icon(Icons.table_chart),
                              label: const Text('Export as CSV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maroonVendor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (filteredReport.isNotEmpty) ...[
                          const Text('Sales Trend (Line Graph)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(
                            height: 220,
                            child: _buildLineChart(filteredReport),
                          ),
                          const SizedBox(height: 24),
                          const Text('Product Stock/Sales Comparison (Bar Graph)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(
                            height: 220,
                            child: _buildBarChart(filteredReport),
                          ),
                          const SizedBox(height: 24),
                        ],
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: size.width,
                              minHeight: size.height * 0.7,
                            ),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Current Stock')),
                                DataColumn(label: Text('Days in Stock')),
                                DataColumn(label: Text('Weekly Sales Rate')),
                                DataColumn(label: Text('Monthly Sales Rate')),
                                DataColumn(label: Text('Depletion Speed (days)')),
                                DataColumn(label: Text('Reorder Level')),
                                DataColumn(label: Text('Priority Score')),
                              ],
                              rows: filteredReport.map((item) => DataRow(cells: [
                                DataCell(Text(item['productName'] ?? '')),
                                DataCell(Text('${item['currentStock']}')),
                                DataCell(Text('${item['daysInStock']}')),
                                DataCell(Text('${item['weeklySalesRate'].toStringAsFixed(2)}')),
                                DataCell(Text('${item['monthlySalesRate'].toStringAsFixed(2)}')),
                                DataCell(Text('${item['depletionSpeedDays'] ?? 'N/A'}')),
                                DataCell(Text('${item['recommendedReorderLevel']}')),
                                DataCell(Text('${item['priorityScore'].toStringAsFixed(2)}')),
                              ])).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLineChart([List<Map<String, dynamic>>? data]) {
    final chartData = data ?? report;
    if (chartData.isEmpty) return const SizedBox();
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.length) return const SizedBox();
                final name = chartData[idx]['productName'] ?? '';
                return SizedBox(
                  width: 50,
                  child: Text(
                    name.length > 6 ? name.substring(0, 6) + '…' : name,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < chartData.length; i++)
                FlSpot(i.toDouble(), (chartData[i]['weeklySalesRate'] as num?)?.toDouble() ?? 0),
            ],
            isCurved: true,
            color: maroonVendor,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart([List<Map<String, dynamic>>? data]) {
    final chartData = data ?? report;
    if (chartData.isEmpty) return const SizedBox();
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.length) return const SizedBox();
                final name = chartData[idx]['productName'] ?? '';
                return SizedBox(
                  width: 50,
                  child: Text(
                    name.length > 6 ? name.substring(0, 6) + '…' : name,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minY: 0,
        barGroups: [
          for (int i = 0; i < chartData.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: (chartData[i]['currentStock'] as num?)?.toDouble() ?? 0,
                color: maroonVendor,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }

  Future<void> _exportAsCSV() async {
    final headers = [
      'Product Name',
      'Current Stock',
      'Days in Stock',
      'Weekly Sales Rate',
      'Monthly Sales Rate',
      'Depletion Speed (days)',
      'Reorder Level',
      'Priority Score',
    ];
    final dataRows = report.map((item) => [
      item['productName'] ?? '',
      '${item['currentStock']}',
      '${item['daysInStock']}',
      '${(item['weeklySalesRate'] as num?)?.toStringAsFixed(2) ?? ''}',
      '${(item['monthlySalesRate'] as num?)?.toStringAsFixed(2) ?? ''}',
      '${item['depletionSpeedDays'] ?? 'N/A'}',
      '${item['recommendedReorderLevel']}',
      '${(item['priorityScore'] as num?)?.toStringAsFixed(2) ?? ''}',
    ]).toList();
    final csvData = const ListToCsvConverter().convert([headers, ...dataRows]);
    if (kIsWeb) {
      // Web: trigger download
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'stock_report.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: use Printing.sharePdf (fallback)
      await Printing.sharePdf(bytes: Uint8List.fromList(csvData.codeUnits), filename: 'stock_report.csv');
    }
  }

  Future<void> _exportAsPDF() async {
    final pdf = pw.Document();
    final headers = [
      'Product Name',
      'Current Stock',
      'Days in Stock',
      'Weekly Sales Rate',
      'Monthly Sales Rate',
      'Depletion Speed (days)',
      'Reorder Level',
      'Priority Score',
    ];
    final dataRows = report.map((item) => [
      item['productName'] ?? '',
      '${item['currentStock']}',
      '${item['daysInStock']}',
      '${(item['weeklySalesRate'] as num?)?.toStringAsFixed(2) ?? ''}',
      '${(item['monthlySalesRate'] as num?)?.toStringAsFixed(2) ?? ''}',
      '${item['depletionSpeedDays'] ?? 'N/A'}',
      '${item['recommendedReorderLevel']}',
      '${(item['priorityScore'] as num?)?.toStringAsFixed(2) ?? ''}',
    ]).toList();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Stock Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text('(Charts not included in PDF export yet)', style: pw.TextStyle(fontSize: 12)),
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
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'stock_report.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    }
  }
} 