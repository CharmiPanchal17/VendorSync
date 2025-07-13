import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  bool submitted = false;
  String newPassword = '';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final role = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                      child: Icon(Icons.lock_reset, size: 40, color: role == 'supplier' ? Colors.green : Colors.blue),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      submitted ? 'Set New Password' : 'Reset Password',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: role == 'supplier' ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      onChanged: (val) {
                        newPassword = val;
                        if (_errorMessage != null) setState(() => _errorMessage = null);
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Submit'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: role == 'supplier' ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        if (newPassword.length < 6) {
                          setState(() => _errorMessage = 'Password must be at least 6 characters');
                          return;
                        }
                        final collection = role == 'supplier' ? 'suppliers' : 'vendors';
                        final query = await FirebaseFirestore.instance
                            .collection(collection)
                            .where('email', isEqualTo: email)
                            .limit(1)
                            .get();
                        if (query.docs.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection(collection)
                              .doc(query.docs.first.id)
                              .update({'password': newPassword});
                          setState(() {
                            _errorMessage = null;
                          });
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: role == 'supplier' ? Colors.green : Colors.blue,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Success',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: role == 'supplier' ? Colors.green : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Password updated! You can now log in.',
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: role == 'supplier' ? Colors.green : Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          setState(() => _errorMessage = 'No account found with this email.');
                        }
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
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