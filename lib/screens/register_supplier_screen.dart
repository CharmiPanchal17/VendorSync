import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class RegisterSupplierScreen extends StatefulWidget {
  const RegisterSupplierScreen({super.key});

  @override
  State<RegisterSupplierScreen> createState() => _RegisterSupplierScreenState();
}

class _RegisterSupplierScreenState extends State<RegisterSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _registerSupplier() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final success = await _authService.register(name, email, password, 'supplier');
        
        if (success) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacementNamed('/supplier-dashboard', arguments: email);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'A supplier with this email already exists.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to register. Please try again.';
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
                            Padding(
                              padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Color(0xFF800000)),
                                  onPressed: () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                  ),
                                ),
                              ),
                            ),
                        ),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF800000).withOpacity(0.1),
                          child: Icon(Icons.local_shipping, size: 40, color: Color(0xFF800000)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Supplier Register',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Color(0xFF800000), fontSize: 32),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Supplier Name',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF800000)),
                                ),
                                onChanged: (val) => name = val,
                                validator: (val) => val == null || val.isEmpty ? 'Enter supplier name' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF800000)),
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
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF800000)),
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
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                  prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF800000)),
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
                                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                                label: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Register as Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: const Color(0xFF800000), // Maroon
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  elevation: 2,
                                  overlayColor: Color(0xFF0D1333), // Dark blue on press
                                ),
                                onPressed: _isLoading ? null : () async {
                                  await _registerSupplier();
                                },
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