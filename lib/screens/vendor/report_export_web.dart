// Web implementation for report export
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> exportCSV(String csvData) async {
  final bytes = csvData.codeUnits;
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'sales_report.csv')
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> exportPDF(List<int> bytes) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'sales_report.pdf')
    ..click();
  html.Url.revokeObjectUrl(url);
} 