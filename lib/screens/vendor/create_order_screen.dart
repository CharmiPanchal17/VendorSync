import 'package:flutter/material.dart';
import '../../mock_data/mock_users.dart';
import '../../models/user.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/email_service.dart';

class VendorCreateOrderScreen extends StatefulWidget {
  final String vendorEmail;
  const VendorCreateOrderScreen({super.key, required this.vendorEmail});

  @override
  State<VendorCreateOrderScreen> createState() => _VendorCreateOrderScreenState();
}

enum OrderMode { singleSupplier, multipleSuppliers }

class OrderItem {
  String productName;
  int quantity;
  User? supplier;
  DateTime? preferredDate;

  OrderItem({this.productName = '', this.quantity = 1, this.supplier, this.preferredDate});
}

class _VendorCreateOrderScreenState extends State<VendorCreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  OrderMode _orderMode = OrderMode.singleSupplier;
  List<User> firestoreSuppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // For single supplier mode
  User? selectedSupplier;
  List<OrderItem> items = [OrderItem()];
  final GlobalKey<AnimatedListState> _singleSupplierListKey = GlobalKey<AnimatedListState>();

  // For multiple suppliers mode
  List<OrderItem> multiSupplierItems = [OrderItem()];
  final GlobalKey<AnimatedListState> _multiSupplierListKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
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

  void _addItem() {
    if (_orderMode == OrderMode.singleSupplier) {
      final index = items.length;
      items.add(OrderItem());
      _singleSupplierListKey.currentState?.insertItem(index);
      setState(() {});
    } else {
      final index = multiSupplierItems.length;
      multiSupplierItems.add(OrderItem());
      _multiSupplierListKey.currentState?.insertItem(index);
      setState(() {});
    }
  }

  void _removeItem(int index) {
    if (_orderMode == OrderMode.singleSupplier) {
      if (items.length > 1) {
        final removed = items.removeAt(index);
        _singleSupplierListKey.currentState?.removeItem(
          index,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: _buildOrderItemFields(removed, index, singleSupplier: true),
          ),
        );
        setState(() {});
      }
    } else {
      if (multiSupplierItems.length > 1) {
        final removed = multiSupplierItems.removeAt(index);
        _multiSupplierListKey.currentState?.removeItem(
          index,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: _buildOrderItemFields(removed, index, singleSupplier: false),
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _submitOrders() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      if (_orderMode == OrderMode.singleSupplier) {
        for (final item in items) {
          await FirebaseFirestore.instance.collection('orders').add({
            'productName': item.productName,
            'quantity': item.quantity,
            'supplierId': selectedSupplier?.id,
            'supplierName': selectedSupplier?.name,
            'supplierEmail': selectedSupplier?.email,
            'vendorEmail': widget.vendorEmail,
            'preferredDeliveryDate': item.preferredDate,
            'status': 'Pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        for (final item in multiSupplierItems) {
          await FirebaseFirestore.instance.collection('orders').add({
            'productName': item.productName,
            'quantity': item.quantity,
            'supplierId': item.supplier?.id,
            'supplierName': item.supplier?.name,
            'supplierEmail': item.supplier?.email,
            'vendorEmail': widget.vendorEmail,
            'preferredDeliveryDate': item.preferredDate,
            'status': 'Pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { _errorMessage = 'Failed to place orders: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order(s)')),
      body: firestoreSuppliers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Option selection
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF43E97B)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<OrderMode>(
                            title: const Text('Multiple items to a single supplier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            value: OrderMode.singleSupplier,
                            groupValue: _orderMode,
                            onChanged: (val) {
                              setState(() { _orderMode = val!; });
                            },
                            activeColor: Colors.white,
                            tileColor: Colors.transparent,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<OrderMode>(
                            title: const Text('Multiple orders to different suppliers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            value: OrderMode.multipleSuppliers,
                            groupValue: _orderMode,
                            onChanged: (val) {
                              setState(() { _orderMode = val!; });
                            },
                            activeColor: Colors.white,
                            tileColor: Colors.transparent,
                          ),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                          child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ListView(
                          key: ValueKey(_orderMode),
                        children: [
                            if (_orderMode == OrderMode.singleSupplier) ...[
                              DropdownButtonFormField<User>(
                                value: selectedSupplier,
                                items: firestoreSuppliers
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => selectedSupplier = val),
                            validator: (val) => val == null ? 'Select supplier' : null,
                                decoration: InputDecoration(
                                  labelText: 'Supplier',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedList(
                                key: _singleSupplierListKey,
                                initialItemCount: items.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index, animation) {
                                  return SizeTransition(
                                    sizeFactor: animation,
                                    child: _buildOrderItemFields(items[index], index, singleSupplier: true),
                                  );
                                },
                              ),
                            ] else ...[
                              AnimatedList(
                                key: _multiSupplierListKey,
                                initialItemCount: multiSupplierItems.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index, animation) {
                                  return SizeTransition(
                                    sizeFactor: animation,
                                    child: _buildOrderItemFields(multiSupplierItems[index], index, singleSupplier: false),
                                    );
                                  },
                                ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Item'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: ((_orderMode == OrderMode.singleSupplier && items.length > 1) ||
                                              (_orderMode == OrderMode.multipleSuppliers && multiSupplierItems.length > 1))
                                          ? () => _removeItem((_orderMode == OrderMode.singleSupplier)
                                              ? items.length - 1
                                              : multiSupplierItems.length - 1)
                                          : null,
                                  icon: const Icon(Icons.remove),
                                  label: const Text('Remove Last'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_errorMessage != null)
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitOrders,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Submit All Orders'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderItemFields(OrderItem item, int index, {required bool singleSupplier}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2196F3))),
            const SizedBox(height: 8),
            if (!singleSupplier)
              DropdownButtonFormField<User>(
                value: item.supplier,
                items: firestoreSuppliers
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => item.supplier = val),
                validator: (val) => val == null ? 'Select supplier' : null,
                decoration: InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.productName,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
              onChanged: (val) => item.productName = val,
              validator: (val) => val == null || val.isEmpty ? 'Enter product name' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.quantity.toString(),
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => item.quantity = int.tryParse(val) ?? 1,
              validator: (val) => val == null || val.isEmpty ? 'Enter quantity' : null,
            ),
            const SizedBox(height: 8),
            GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                  initialDate: item.preferredDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                                                primary: Color(0xFF2196F3),
                                                onPrimary: Colors.white,
                          surface: Color(0xFF43E97B),
                                                onSurface: Colors.black,
                                              ),
                        dialogBackgroundColor: Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                              );
                if (picked != null) setState(() => item.preferredDate = picked);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                  color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                                    ),
                                          child: Text(
                  item.preferredDate != null
                      ? 'Delivery Date: ${DateFormat.yMMMd().format(item.preferredDate!)}'
                      : 'Select Delivery Date',
                  style: TextStyle(
                    color: item.preferredDate != null ? Colors.green.shade900 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 