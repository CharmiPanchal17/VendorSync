import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String role = 'vendor';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && (arg == 'vendor' || arg == 'supplier')) {
      role = arg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  Color(0xFF2196F3), // Blue
                  Color(0xFF43E97B), // Green
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
                          backgroundColor: (role == 'supplier' ? Colors.green : Colors.blue).withOpacity(0.1),
                          child: Icon(
                            role == 'supplier' ? Icons.local_shipping : Icons.store,
                            size: 40,
                            color: role == 'supplier' ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          role == 'supplier' ? 'Supplier Login' : 'Vendor Login',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: role == 'supplier' ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
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
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/reset-password', arguments: role);
                                    },
                                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  icon: const Icon(Icons.login),
                                  label: _isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Login'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: role == 'supplier' ? Colors.green : Colors.blue,
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
                                        final collection = role == 'vendor' ? 'vendors' : 'suppliers';
                                        final dashboardRoute = role == 'vendor' ? '/vendor-dashboard' : '/supplier-dashboard';
                                        final query = await FirebaseFirestore.instance
                                          .collection(collection)
                                          .where('email', isEqualTo: email)
                                          .limit(1)
                                          .get();
                                        if (query.docs.isNotEmpty) {
                                          final user = query.docs.first.data();
                                          if (user['password'] == password) {
                                            setState(() => _isLoading = false);
                                            Navigator.of(context).pushReplacementNamed(dashboardRoute);
                                          } else {
                                            setState(() {
                                              _isLoading = false;
                                              _errorMessage = 'Incorrect password.';
                                            });
                                          }
                                        } else {
                                          setState(() {
                                            _isLoading = false;
                                            _errorMessage = 'No account found with this email.';
                                          });
                                        }
                                      } catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                          _errorMessage = 'Login failed. Please try again.';
                                        });
                                      }
                                    }
                                  },
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                                if (role == 'vendor') ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                                    label: const Text('Don\'t have an account? Register', style: TextStyle(color: Colors.blue)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: const BorderSide(color: Colors.blue),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/register');
                                    },
                                  ),
                                ],
                              ],
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
        ],
      ),
    );
  }
} 