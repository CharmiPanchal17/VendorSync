import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSupplierScreen extends StatefulWidget {
  final String vendorEmail;
  const AddSupplierScreen({super.key, required this.vendorEmail});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _addSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Check if supplier with this email already exists
        final existingSuppliers = await FirebaseFirestore.instance
            .collection('suppliers')
            .where('email', isEqualTo: email)
            .get();

        String supplierId;
        
        if (existingSuppliers.docs.isNotEmpty) {
          // Supplier already exists, use their ID
          supplierId = existingSuppliers.docs.first.id;
        } else {
          // Create new supplier
          final supplierDoc = await FirebaseFirestore.instance.collection('suppliers').add({
            'name': name,
            'email': email,
            'role': 'supplier',
            'createdAt': FieldValue.serverTimestamp(),
          });
          supplierId = supplierDoc.id;
        }

        // Check if this vendor-supplier relationship already exists
        final existingRelationship = await FirebaseFirestore.instance
            .collection('vendor_suppliers')
            .where('vendorEmail', isEqualTo: widget.vendorEmail)
            .where('supplierId', isEqualTo: supplierId)
            .get();

        if (existingRelationship.docs.isNotEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'This supplier is already in your list.';
          });
          return;
        }

        // Add vendor-supplier relationship
        await FirebaseFirestore.instance.collection('vendor_suppliers').add({
          'vendorEmail': widget.vendorEmail,
          'supplierId': supplierId,
          'addedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isLoading = false);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name added to your suppliers successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          
          // Navigate back
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to add supplier. Please check your connection and try again.';
        });
        print('Add supplier error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Supplier'),
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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Icon(Icons.person_add, size: 40, color: Colors.blue),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Add New Supplier',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a supplier to your network',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Supplier Name / Business Name',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                              ),
                              onChanged: (val) => name = val,
                              validator: (val) => val == null || val.isEmpty 
                                ? 'Enter supplier name' 
                                : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (val) => email = val,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Enter email address';
                                }
                                if (!val.contains('@')) {
                                  return 'Email must contain @';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade600),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: Colors.red.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_errorMessage != null) const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, 
                                        color: Colors.white
                                      )
                                    )
                                  : const Icon(Icons.person_add_alt_1),
                              label: _isLoading
                                  ? const Text('Adding Supplier...')
                                  : const Text('Add Supplier'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                elevation: 2,
                              ),
                              onPressed: _isLoading ? null : _addSupplier,
                            ),
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
      ),
    );
  }
} 