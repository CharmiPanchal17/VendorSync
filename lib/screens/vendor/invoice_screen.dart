import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceScreen extends StatelessWidget {
  final String? orderId;
  final String? vendorEmail;

  const InvoiceScreen({Key? key, this.orderId, this.vendorEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (orderId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('No order ID provided.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text('INVOICE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
                              ),
                              Icon(Icons.receipt_long, color: Color(0xFF43E97B), size: 32),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(thickness: 2, color: Colors.blue.shade100),
                          const SizedBox(height: 16),
                          Text('Order ID: $orderId', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Vendor: ${data['vendorEmail'] ?? vendorEmail ?? 'N/A'}'),
                          Text('Supplier: ${data['supplierName'] ?? 'N/A'}'),
                          Text('Product: ${data['productName'] ?? 'N/A'}'),
                          Text('Quantity: ${data['quantity'] ?? 'N/A'}'),
                          if (data['price'] != null) Text('Price: ${data['price']}'),
                          if (data['preferredDeliveryDate'] != null)
                            Text('Delivery Date: ${data['preferredDeliveryDate'].toDate().toString().split(' ')[0]}'),
                          Text('Status: ${data['status'] ?? 'N/A'}'),
                          const SizedBox(height: 24),
                          Divider(thickness: 1, color: Colors.green.shade100),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('Thank you for your business!', style: TextStyle(color: Color(0xFF43E97B), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 