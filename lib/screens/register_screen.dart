import 'package:flutter/material.dart';
import '../models/user.dart';

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
                            validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            onChanged: (val) => password = val,
                            validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            onChanged: (val) => confirmPassword = val,
                            validator: (val) => val == null || val.isEmpty ? 'Confirm your password' : (val != password ? 'Passwords do not match' : null),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Register'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.of(context).pushReplacementNamed('/register-suppliers');
                              }
                            },
                          ),
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