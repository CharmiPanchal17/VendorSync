import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterSuppliersScreen extends StatefulWidget {
  final String vendorEmail;
  const RegisterSuppliersScreen({super.key, required this.vendorEmail});

  @override
  State<RegisterSuppliersScreen> createState() => _RegisterSuppliersScreenState();
}

class _RegisterSuppliersScreenState extends State<RegisterSuppliersScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  final List<Map<String, String>> suppliers = [];

  void _addSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        suppliers.add({'name': name, 'email': email, 'password': password});
        name = '';
        email = '';
        password = '';
        confirmPassword = '';
      });
      _formKey.currentState!.reset();
      // Save to Firestore
      await FirebaseFirestore.instance.collection('suppliers').add({
        'name': suppliers.last['name'],
        'email': suppliers.last['email'],
        'password': suppliers.last['password'],
        'vendorEmail': widget.vendorEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
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
                      child: Icon(Icons.group_add, size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Register Suppliers',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Supplier Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            onChanged: (val) => name = val,
                            validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Supplier Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (val) => email = val,
                            validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            onChanged: (val) => password = val,
                            validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            onChanged: (val) => confirmPassword = val,
                            validator: (val) => val == null || val.isEmpty ? 'Confirm your password' : (val != password ? 'Passwords do not match' : null),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add Supplier'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            onPressed: _addSupplier,
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
    );
  }
} 