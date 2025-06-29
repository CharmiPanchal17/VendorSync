import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableSuppliersScreen extends StatelessWidget {
  final String vendorEmail;
  const AvailableSuppliersScreen({super.key, required this.vendorEmail});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Suppliers'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                : [const Color(0xFF2196F3), const Color(0xFF43E97B)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
              : [const Color(0xFF2196F3), const Color(0xFF43E97B)],
          ),
        ),
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
                    color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading your suppliers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final vendorSupplierDocs = vendorSuppliersSnapshot.data?.docs ?? [];
            final addedSupplierIds = vendorSupplierDocs.map((doc) => doc['supplierId'] as String).toSet();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('suppliers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading available suppliers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark 
                                  ? [colorScheme.primary, colorScheme.secondary]
                                  : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.people_outline, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Suppliers Available',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Suppliers need to register first before they appear here',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final availableSuppliers = docs.where((doc) => !addedSupplierIds.contains(doc.id)).toList();
                final addedSuppliers = docs.where((doc) => addedSupplierIds.contains(doc.id)).toList();
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.add_business, size: 32, color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Available Suppliers',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${availableSuppliers.length} supplier${availableSuppliers.length == 1 ? '' : 's'} available to add',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? colorScheme.primary.withOpacity(0.2) : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? colorScheme.primary.withOpacity(0.3) : Colors.green.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    '${availableSuppliers.length}',
                                    style: TextStyle(
                                      color: isDark ? colorScheme.primary : Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (addedSuppliers.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark ? colorScheme.primary.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                                      isDark ? colorScheme.primary.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      isDark ? colorScheme.primary.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 20, color: isDark ? colorScheme.primary : Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${addedSuppliers.length} supplier${addedSuppliers.length == 1 ? '' : 's'} already added',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Available Suppliers List
                      if (availableSuppliers.isNotEmpty) ...[
                        Text(
                          'Available to Add',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: availableSuppliers.length,
                            itemBuilder: (context, index) {
                              final data = availableSuppliers[index].data() as Map<String, dynamic>;
                              final docId = availableSuppliers[index].id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
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
                                      gradient: LinearGradient(
                                        colors: isDark 
                                          ? [colorScheme.primary, colorScheme.secondary]
                                          : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                                  ),
                                  title: Text(
                                    data['name'] ?? 'Unknown Supplier',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        data['email'] ?? 'No email provided',
                                        style: TextStyle(
                                          color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.green.shade400 : Colors.green.shade200,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add_circle, color: Colors.green.shade600, size: 24),
                                      tooltip: 'Add Supplier',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            backgroundColor: isDark ? colorScheme.surface : Colors.white,
                                            elevation: 20,
                                            contentPadding: const EdgeInsets.all(24),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: isDark 
                                                        ? [colorScheme.primary, colorScheme.secondary]
                                                        : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Icon(Icons.person_add, size: 32, color: Colors.white),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  'Add Supplier',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Are you sure you want to add ${data['name']} to your suppliers list?',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
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
                                                          side: BorderSide(
                                                            color: isDark ? colorScheme.onSurface.withOpacity(0.3) : Colors.grey,
                                                          ),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                                        ),
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF4CAF50),
                                                          foregroundColor: Colors.white,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                                          elevation: 2,
                                                        ),
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: const Text(
                                                          'Add Supplier',
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
                                          await FirebaseFirestore.instance.collection('vendor_suppliers').add({
                                            'vendorEmail': vendorEmail,
                                            'supplierId': docId,
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${data['name']} added to your suppliers'),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark 
                                          ? [colorScheme.primary, colorScheme.secondary]
                                          : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.check_circle, size: 48, color: Colors.white),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'All Suppliers Added!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'You have added all available suppliers to your network',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 