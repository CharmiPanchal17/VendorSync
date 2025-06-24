import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../register_suppliers_screen.dart';

class SuppliersListScreen extends StatelessWidget {
  final String vendorEmail;
  const SuppliersListScreen({super.key, required this.vendorEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Suppliers')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('suppliers')
                  .where('vendorEmail', isEqualTo: vendorEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading suppliers'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No suppliers found.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('suppliers').doc(docId).delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SizedBox(
              width: 180,
              height: 36,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Register Supplier', style: TextStyle(fontSize: 14)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RegisterSuppliersScreen(vendorEmail: vendorEmail),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 