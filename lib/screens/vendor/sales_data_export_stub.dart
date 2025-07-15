// Stub for sales data export (non-web platforms)
Future<void> exportCSV(String csvData) async {
  throw UnimplementedError('CSV export is only available on web.');
}

Future<void> exportPDF(List<int> bytes) async {
  throw UnimplementedError('PDF export is only available on web.');
} 