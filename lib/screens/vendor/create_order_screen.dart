import 'package:flutter/material.dart';
import '../../mock_data/mock_users.dart';
import '../../models/user.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorCreateOrderScreen extends StatefulWidget {
  final String vendorEmail;
  const VendorCreateOrderScreen({super.key, required this.vendorEmail});

  @override
  State<VendorCreateOrderScreen> createState() => _VendorCreateOrderScreenState();
}

class _VendorCreateOrderScreenState extends State<VendorCreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String productName = '';
  int quantity = 1;
  User? selectedSupplier;
  DateTime? preferredDate;
  List<User> firestoreSuppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    // Get supplier IDs from vendor_suppliers
    final vendorSuppliersQuery = await FirebaseFirestore.instance
        .collection('vendor_suppliers')
        .where('vendorEmail', isEqualTo: widget.vendorEmail)
        .get();
    final supplierIds = vendorSuppliersQuery.docs.map((doc) => doc['supplierId'] as String).toList();
    if (supplierIds.isEmpty) {
      setState(() {
        firestoreSuppliers = [];
      });
      return;
    }
    // Get supplier details from suppliers collection
    final suppliersQuery = await FirebaseFirestore.instance
        .collection('suppliers')
        .where(FieldPath.documentId, whereIn: supplierIds)
        .get();
    setState(() {
      firestoreSuppliers = suppliersQuery.docs.map((doc) => User(
        id: doc.id,
        name: doc['name'],
        email: doc['email'],
        role: UserRole.supplier,
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2196F3), // Blue
                Color(0xFF43E97B), // Green
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3), // Blue
              Color(0xFF43E97B), // Green
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Card(
          margin: EdgeInsets.zero,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                color: Colors.transparent,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Builder(
                      builder: (context) =>
                        Navigator.canPop(context)
                          ? Padding(
                                padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    CircleAvatar(
                      radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.add_shopping_cart, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                      const Text(
                        'Create New Order',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                    Text(
                        'Fill in the details to create your order',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('vendor_suppliers')
                                      .where('vendorEmail', isEqualTo: widget.vendorEmail)
                                      .snapshots(),
                                  builder: (context, vendorSuppliersSnapshot) {
                                    if (vendorSuppliersSnapshot.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.grey.shade50,
                                        ),
                                        child: const Row(
                                          children: [
                                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                            SizedBox(width: 12),
                                            Text('Loading suppliers...'),
                                          ],
                                        ),
                                      );
                                    }
                                    final vendorSupplierDocs = vendorSuppliersSnapshot.data?.docs ?? [];
                                    final supplierIds = vendorSupplierDocs.map((doc) => doc['supplierId'] as String).toList();
                                    if (supplierIds.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'No suppliers found. Please add a supplier first.',
                                                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('suppliers')
                                          .where(FieldPath.documentId, whereIn: supplierIds)
                                          .snapshots(),
                                      builder: (context, suppliersSnapshot) {
                                        if (suppliersSnapshot.connectionState == ConnectionState.waiting) {
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.grey.shade50,
                                            ),
                                            child: const Row(
                                              children: [
                                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                                SizedBox(width: 12),
                                                Text('Loading suppliers...'),
                                              ],
                                            ),
                                          );
                                        }
                                        final supplierDocs = suppliersSnapshot.data?.docs ?? [];
                                        final suppliers = supplierDocs.map((doc) => User(
                                          id: doc.id,
                                          name: doc['name'],
                                          email: doc['email'],
                                          role: UserRole.supplier,
                                        )).toList();
                                        return DropdownButtonFormField<User>(
                                          decoration: InputDecoration(
                              labelText: 'Select Supplier',
                                            prefixIcon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                          ),
                                          value: selectedSupplier != null && suppliers.any((s) => s.id == selectedSupplier!.id)
                                              ? suppliers.firstWhere((s) => s.id == selectedSupplier!.id)
                                              : null,
                                          items: suppliers
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => selectedSupplier = val),
                            validator: (val) => val == null ? 'Select supplier' : null,
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Product Name',
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  onChanged: (val) => productName = val,
                                  validator: (val) => val == null || val.isEmpty ? 'Enter product name' : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.numbers, color: Colors.white, size: 20),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                                  validator: (val) => val == null || val.isEmpty ? 'Enter quantity' : null,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2196F50), Color(0xFF43E97B)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                    ),
                                    title: Text(
                                      preferredDate == null
                                          ? 'Preferred Delivery Date'
                                          : 'Preferred Delivery Date: ${DateFormat.yMMMd().format(preferredDate!)}',
                                      style: TextStyle(
                                        color: preferredDate == null ? Colors.grey.shade600 : Colors.black,
                                        fontWeight: preferredDate == null ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: const ColorScheme.light(
                                                primary: Color(0xFF2196F3),
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                              );
                              if (picked != null) {
                                setState(() => preferredDate = picked);
                              }
                            },
                          ),
                                ),
                                const SizedBox(height: 32),
                          FilledButton.icon(
                                  icon: _isLoading 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.check_circle),
                                  label: _isLoading ? const Text('Creating Order...') : const Text('Create Order'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    elevation: 2,
                                  ),
                            onPressed: _isLoading ? null : () async {
                              if (_formKey.currentState!.validate() && preferredDate != null) {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                try {
                                  await FirebaseFirestore.instance.collection('orders').add({
                                    'productName': productName,
                                    'quantity': quantity,
                                    'supplierId': selectedSupplier?.id,
                                    'supplierName': selectedSupplier?.name,
                                    'supplierEmail': selectedSupplier?.email,
                                    'vendorEmail': widget.vendorEmail,
                                    'preferredDeliveryDate': preferredDate,
                                    'status': 'Pending',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  setState(() => _isLoading = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Order created successfully!'),
                                              backgroundColor: Colors.green,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                  Navigator.of(context).pop();
                                        }
                                } catch (e) {
                                  setState(() {
                                    _isLoading = false;
                                    _errorMessage = 'Failed to create order. Please try again.';
                                  });
                                }
                                    } else if (preferredDate == null) {
                                      setState(() {
                                        _errorMessage = 'Please select a preferred delivery date.';
                                      });
                              }
                            },
                          ),
                          if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 