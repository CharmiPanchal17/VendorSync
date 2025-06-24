import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                      child: Icon(
                        role == 'supplier' ? Icons.local_shipping : Icons.store,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      role == 'supplier' ? 'Supplier Login' : 'Vendor Login',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
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
                            label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            onPressed: _isLoading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                try {
                                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                                    email: email,
                                    password: password,
                                  );
                                  setState(() => _isLoading = false);
                                  if (role == 'vendor') {
                                    Navigator.of(context).pushReplacementNamed('/vendor-dashboard');
                                  } else {
                                    Navigator.of(context).pushReplacementNamed('/supplier-dashboard');
                                  }
                                } on FirebaseAuthException catch (e) {
                                  setState(() {
                                    _isLoading = false;
                                    if (e.code == 'user-not-found') {
                                      _errorMessage = 'No user found for that email.';
                                    } else if (e.code == 'wrong-password') {
                                      _errorMessage = 'Wrong password provided.';
                                    } else {
                                      _errorMessage = 'Login failed. Please try again.';
                                    }
                                  });
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
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          ],
                          if (role == 'vendor') ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Don\'t have an account? Register'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                              onPressed: () {
                                Navigator.of(context).pushNamed('/register');
                              },
                            ),
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