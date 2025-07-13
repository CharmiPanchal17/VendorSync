import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'available_suppliers_screen.dart';

class SuppliersListScreen extends StatelessWidget {
  final String vendorEmail;
  const SuppliersListScreen({super.key, required this.vendorEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Suppliers'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vendor_suppliers')
              .where('vendorEmail', isEqualTo: vendorEmail)
              .snapshots(),
          builder: (context, vendorSuppliersSnapshot) {
            if (vendorSuppliersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }
            if (vendorSuppliersSnapshot.hasError) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading your suppliers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final vendorSupplierDocs = vendorSuppliersSnapshot.data?.docs ?? [];
            if (vendorSupplierDocs.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
        children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.people_outline, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Suppliers Yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add suppliers to start managing your orders',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AvailableSuppliersScreen(vendorEmail: vendorEmail),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Supplier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final supplierIds = vendorSupplierDocs.map((doc) => doc['supplierId'] as String).toList();
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('suppliers')
                  .where(FieldPath.documentId, whereIn: supplierIds)
                  .snapshots(),
              builder: (context, suppliersSnapshot) {
                if (suppliersSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }
                if (suppliersSnapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading suppliers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final supplierDocs = suppliersSnapshot.data?.docs ?? [];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1976D2), // Darker blue
                              Color(0xFF42A5F5), // Lighter blue
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people, size: 32, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'My Suppliers',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${supplierDocs.length} supplier${supplierDocs.length == 1 ? '' : 's'} in your network',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${supplierDocs.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Suppliers List
                      Expanded(
                        child: ListView.builder(
                          itemCount: supplierDocs.length,
                  itemBuilder: (context, index) {
                            final data = supplierDocs[index].data() as Map<String, dynamic>;
                            final supplierId = supplierDocs[index].id;
                            // Find the vendor_suppliers doc for this supplier
                            final vendorSupplierDocList = vendorSupplierDocs.where((doc) => doc['supplierId'] == supplierId).toList();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                      child: ListTile(
                                contentPadding: const EdgeInsets.all(20),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                                ),
                                title: Text(
                                  data['name'] ?? 'Unknown Supplier',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      data['email'] ?? 'No email provided',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: vendorSupplierDocList.isNotEmpty
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.remove_circle, color: Colors.red.shade600, size: 24),
                                          tooltip: 'Remove from My Suppliers',
                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                                backgroundColor: Colors.white,
                                                elevation: 20,
                                                contentPadding: const EdgeInsets.all(24),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [Colors.red, Colors.redAccent],
                                                        ),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Icon(Icons.person_remove, size: 32, color: Colors.white),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    const Text(
                                                      'Remove Supplier',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1A1A1A),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Are you sure you want to remove ${data['name']} from your suppliers list?',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'This action cannot be undone.',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.red.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 24),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: () => Navigator.of(context).pop(false),
                                                            style: OutlinedButton.styleFrom(
                                                              side: const BorderSide(color: Colors.grey),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                            ),
                                                            child: const Text(
                                                              'Cancel',
                                                              style: TextStyle(color: Colors.grey),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.red,
                                                              foregroundColor: Colors.white,
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              elevation: 2,
                                                            ),
                                                            onPressed: () => Navigator.of(context).pop(true),
                                                            child: const Text(
                                                              'Remove',
                                                              style: TextStyle(fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                            if (confirm == true) {
                                              await FirebaseFirestore.instance
                                                  .collection('vendor_suppliers')
                                                  .doc(vendorSupplierDocList.first.id)
                                                  .delete();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${data['name']} removed from your suppliers'),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                builder: (context) => AvailableSuppliersScreen(vendorEmail: vendorEmail),
                    ),
                  );
                },
          tooltip: 'Add Supplier',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
} 