// import 'package:flutter/material.dart';

// class VendorInvoicesScreen extends StatelessWidget {
//   const VendorInvoicesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final invoices = [
//       {
//         'id': 'INV-1001',
//         'amount': 250.0,
//         'status': 'Paid',
//         'date': '2025-06-20',
//       },
//       {
//         'id': 'INV-1002',
//         'amount': 420.0,
//         'status': 'Unpaid',
//         'date': '2025-06-22',
//       },
//       {
//         'id': 'INV-1003',
//         'amount': 315.5,
//         'status': 'Paid',
//         'date': '2025-06-24',
//       },
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Invoices & Receipts'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: invoices.length,
//         itemBuilder: (context, index) {
//           final invoice = invoices[index];
//           return Card(
//             elevation: 2,
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             child: ListTile(
//               leading: Icon(
//                 invoice['status'] == 'Paid'
//                     ? Icons.receipt_long
//                     : Icons.warning_amber,
//                 color: invoice['status'] == 'Paid'
//                     ? Colors.green
//                     : Colors.orange,
//               ),
//               title: Text('Invoice ID: ${invoice['id']}'),
//               subtitle: Text(
//                 'Date: ${invoice['date']}\nAmount: \$${invoice['amount']}',
//               ),
//               trailing: Chip(
//                 label: Text(invoice['status']),
//                 backgroundColor: invoice['status'] == 'Paid'
//                     ? Colors.green.shade100
//                     : Colors.orange.shade100,
//               ),
//               onTap: () {
//                 // Implement invoice detail navigation if needed
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class VendorInvoicesScreen extends StatelessWidget {
  const VendorInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Object>> invoices = [
      {
        'id': 'INV-1001',
        'amount': 250.0,
        'status': 'Paid',
        'date': '2025-06-20',
      },
      {
        'id': 'INV-1002',
        'amount': 420.0,
        'status': 'Unpaid',
        'date': '2025-06-22',
      },
      {
        'id': 'INV-1003',
        'amount': 315.5,
        'status': 'Paid',
        'date': '2025-06-24',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices & Receipts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final Map<String, Object> invoice = invoices[index];

          final String id = invoice['id'] as String;
          final double amount = invoice['amount'] as double;
          final String status = invoice['status'] as String;
          final String date = invoice['date'] as String;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                status == 'Paid' ? Icons.receipt_long : Icons.warning_amber,
                color: status == 'Paid' ? Colors.green : Colors.orange,
              ),
              title: Text('Invoice ID: $id'),
              subtitle: Text(
                'Date: $date\nAmount: \$${amount.toStringAsFixed(2)}',
              ),
              trailing: Chip(
                label: Text(status),
                backgroundColor: status == 'Paid'
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
              ),
              onTap: () {
                // Optional: Add logic to view invoice details
              },
            ),
          );
        },
      ),
    );
  }
}
