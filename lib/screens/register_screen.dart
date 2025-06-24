import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  final UserRole role = UserRole.vendor;
  bool _isLoading = false;
  String? _errorMessage;

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
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.store, size: 40, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vendor Register',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            onChanged: (val) => name = val,
                            validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
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
                            label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            onPressed: _isLoading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                try {
                                  // Register with Firebase Auth
                                  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                                  // Save vendor info to Firestore
                                  await FirebaseFirestore.instance.collection('vendors').doc(credential.user!.uid).set({
                                    'name': name,
                                    'email': email,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  setState(() => _isLoading = false);
                                  Navigator.of(context).pushReplacementNamed('/register-suppliers');
                                } on FirebaseAuthException catch (e) {
                                  setState(() {
                                    _isLoading = false;
                                    if (e.code == 'email-already-in-use') {
                                      _errorMessage = 'Email is already registered.';
                                    } else if (e.code == 'invalid-email') {
                                      _errorMessage = 'Invalid email address.';
                                    } else if (e.code == 'weak-password') {
                                      _errorMessage = 'Password is too weak.';
                                    } else {
                                      _errorMessage = 'Registration failed. Please try again.';
                                    }
                                  });
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
                            icon: const Icon(Icons.login),
                            label: const Text('Already have an account? Login'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/login', arguments: 'vendor');
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
    );
  }
} 