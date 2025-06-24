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
    final query = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('vendorEmail', isEqualTo: widget.vendorEmail)
        .get();
    setState(() {
      firestoreSuppliers = query.docs.map((doc) => User(
        id: doc.id,
        name: doc['name'],
        email: doc['email'],
        role: UserRole.supplier,
      )).toList();
    });
    print('Fetched suppliers: \\${firestoreSuppliers.length}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.2),
      body: SafeArea(
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 8,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Builder(
                      builder: (context) =>
                        Navigator.canPop(context)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.add_shopping_cart, size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create New Order',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Product Name',
                              prefixIcon: Icon(Icons.shopping_bag_outlined),
                            ),
                            onChanged: (val) => productName = val,
                            validator: (val) => val == null || val.isEmpty ? 'Enter product name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                            validator: (val) => val == null || val.isEmpty ? 'Enter quantity' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<User>(
                            decoration: const InputDecoration(
                              labelText: 'Select Supplier',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            value: selectedSupplier,
                            items: firestoreSuppliers
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => selectedSupplier = val),
                            validator: (val) => val == null ? 'Select supplier' : null,
                          ),
                          if (firestoreSuppliers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'No suppliers found. Please register a supplier first.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(preferredDate == null
                                ? 'Preferred Delivery Date'
                                : 'Preferred Delivery Date: ${DateFormat.yMMMd().format(preferredDate!)}'),
                            leading: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => preferredDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Order'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
                                  Navigator.of(context).pop();
                                } catch (e) {
                                  setState(() {
                                    _isLoading = false;
                                    _errorMessage = 'Failed to create order. Please try again.';
                                  });
                                }
                              }
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 