import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';

class RegisterSupplierScreen extends StatefulWidget {
  const RegisterSupplierScreen({super.key});

  @override
  State<RegisterSupplierScreen> createState() => _RegisterSupplierScreenState();
}

class _RegisterSupplierScreenState extends State<RegisterSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF43E97B), // Green
                  Color(0xFF38F9D7), // Lighter green/teal
                ],
              ),
            ),
          ),
          // White overlay to soften the gradient
          Container(
            color: Colors.white.withOpacity(0.6),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0, // No shadow
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  color: Colors.transparent, // Fully transparent
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
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: Icon(Icons.local_shipping, size: 40, color: Colors.green),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Supplier Register',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
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
                                validator: (val) => val == null || val.isEmpty ? 'Enter supplier name' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (val) => email = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Enter email';
                                  }
                                  if (!val.contains('@')) {
                                    return 'Email must contain @';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                onChanged: (val) => password = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Enter password';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                                onChanged: (val) => confirmPassword = val,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Confirm your password';
                                  }
                                  if (val != password) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                icon: const Icon(Icons.person_add_alt_1),
                                label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register as Supplier'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  elevation: 2,
                                ),
                                onPressed: _isLoading ? null : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                    });
                                    try {
                                      final docRef = await FirebaseFirestore.instance.collection('suppliers').add({
                                        'name': name,
                                        'email': email,
                                        'password': password,
                                        'createdAt': FieldValue.serverTimestamp(),
                                        'vendorEmail': null,
                                      });
                                      
                                      // Save session data for automatic login
                                      await SessionService.saveSession(
                                        email: email,
                                        role: 'supplier',
                                        userId: docRef.id,
                                      );
                                      
                                      setState(() => _isLoading = false);
                                      Navigator.of(context).pushReplacementNamed('/supplier-dashboard', arguments: email);
                                    } catch (e) {
                                      setState(() {
                                        _isLoading = false;
                                        _errorMessage = 'Failed to register. Please try again.';
                                      });
                                    }
                                  }
                                },
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              ],
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.login, color: Colors.green),
                                label: const Text('Already have an account? Login', style: TextStyle(color: Colors.green)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: const BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed('/login', arguments: 'supplier');
                                },
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
        ],
      ),
    );
  }
} 