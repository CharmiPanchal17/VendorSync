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
  bool _newPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final role = ModalRoute.of(context)?.settings.arguments as String?;
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
                    child: submitted
                        ? Column(
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
                                child: Icon(Icons.lock_reset, size: 40, color: Color(0xFF800000)),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                submitted ? 'Set New Password' : 'Reset Password',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF800000),
                                  fontSize: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'New Password',
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
                                    icon: Icon(_newPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFF800000)),
                                    onPressed: () {
                                      setState(() {
                                        _newPasswordVisible = !_newPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_newPasswordVisible,
                                onChanged: (val) {
                                  newPassword = val;
                                  if (_errorMessage != null) setState(() => _errorMessage = null);
                                },
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                icon: const Icon(Icons.save, color: Colors.white),
                                label: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: Color(0xFF800000),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  elevation: 2,
                                  overlayColor: Color(0xFF0D1333),
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
                                              color: Color(0xFF800000),
                                              size: 64,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Success',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF800000),
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
                                                  backgroundColor: Color(0xFF800000),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          )
                        : Column(
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
                                child: Icon(Icons.lock_reset, size: 40, color: Color(0xFF800000)),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                submitted ? 'Set New Password' : 'Reset Password',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF800000),
                                  fontSize: 32,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Text(
                                      'Enter your ${role ?? ''} email to receive a reset link:',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      decoration: InputDecoration(
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
                                      onChanged: (val) {
                                        email = val;
                                        if (_errorMessage != null) setState(() => _errorMessage = null);
                                      },
                                      validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      icon: const Icon(Icons.send, color: Colors.white),
                                      label: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        backgroundColor: Color(0xFF800000),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                        elevation: 2,
                                        overlayColor: Color(0xFF0D1333),
                                      ),
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          final collection = role == 'supplier' ? 'suppliers' : 'vendors';
                                          final query = await FirebaseFirestore.instance
                                              .collection(collection)
                                              .where('email', isEqualTo: email)
                                              .limit(1)
                                              .get();
                                          if (query.docs.isNotEmpty) {
                                            setState(() {
                                              submitted = true;
                                              _errorMessage = null;
                                            });
                                          } else {
                                            setState(() {
                                              _errorMessage = 'No account found with this email.';
                                            });
                                          }
                                        }
                                      },
                                    ),
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                        textAlign: TextAlign.center,
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
        ],
      ),
    );
  }
} 