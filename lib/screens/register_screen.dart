import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Add color constant at the top-level for use throughout the file
const maroonPopup = Color(0xFF800000);

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
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  Future<void> _registerVendor() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Check if vendor with this email already exists
        final existingVendors = await FirebaseFirestore.instance
            .collection('vendors')
            .where('email', isEqualTo: email)
            .get();

        if (existingVendors.docs.isNotEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'A vendor with trhis email already exists.';
          });
          return;
        }

        // Add new vendor to Firestore
        await FirebaseFirestore.instance.collection('vendors').add({
          'name': name,
          'email': email,
          'password': password, // Note: In production, this should be hashed
          'role': 'vendor',
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isLoading = false);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful! Welcome to VendorSync.'),
              backgroundColor: maroonPopup,
            ),
          );
          
          // Navigate to vendor dashboard
          Navigator.of(context).pushReplacementNamed('/vendor-dashboard');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to register. Please check your connection and try again.';
        });
        print('Registration error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Solid light cyan background to match welcome page
          Container(
            color: const Color(0xFFAFFFFF),
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
                                      icon: const Icon(Icons.arrow_back, color: Color(0xFF800000)),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF800000).withOpacity(0.1),
                          child: Icon(Icons.store, size: 40, color: Color(0xFF800000)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Vendor Register',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Color(0xFF800000), fontSize: 32),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Vendor Name',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF800000)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000), width: 2),
                                  ),
                                ),
                                onChanged: (val) => name = val,
                                validator: (val) => val == null || val.isEmpty ? 'Enter vendor name' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF800000)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000), width: 2),
                                  ),
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
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF800000)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000), width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFF800000)),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_passwordVisible,
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
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF800000)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF800000), width: 2),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFF800000)),
                                    onPressed: () {
                                      setState(() {
                                        _confirmPasswordVisible = !_confirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_confirmPasswordVisible,
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
                                label: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Register as Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: const Color(0xFF800000), // Maroon
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  elevation: 2,
                                  overlayColor: Color(0xFF0D1333), // Dark blue on press
                                ),
                                onPressed: _isLoading ? null : _registerVendor,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.login, color: Color(0xFF800000)),
                                label: const Text('Already have an account? Login', style: TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: const BorderSide(color: Color(0xFF800000)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
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
        ],
      ),
    );
  }
} 