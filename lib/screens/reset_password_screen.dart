import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final role = ModalRoute.of(context)?.settings.arguments as String?;
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
                            child: Icon(Icons.mark_email_read, size: 40, color: colorScheme.primary),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Check your email!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text('A password reset link has been sent to your email.'),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text('Back to Login'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
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
                            child: Icon(Icons.lock_reset, size: 40, color: colorScheme.primary),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Reset Password',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                Text(
                                  'Enter your ${role ?? ''} email to receive a reset link:',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (val) => email = val,
                                  validator: (val) => val == null || val.isEmpty ? 'Enter email' : null,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  icon: const Icon(Icons.send),
                                  label: const Text('Send Reset Link'),
                                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => submitted = true);
                                    }
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