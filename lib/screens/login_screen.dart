import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = await _authService.login(email, password, role);
        
        if (user != null) {
          setState(() => _isLoading = false);
          if (role == 'vendor') {
            Navigator.of(context).pushReplacementNamed('/vendor-dashboard', arguments: email);
          } else {
            Navigator.of(context).pushReplacementNamed('/supplier-dashboard', arguments: email);
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Invalid email or password.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed. Please try again.';
        });
        print('Login error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const maroon = Color(0xFF800000);
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
                          child: Icon(
                            role == 'supplier' ? Icons.local_shipping : Icons.store,
                            size: 40,
                            color: Color(0xFF800000),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          role == 'supplier' ? 'Supplier Login' : 'Vendor Login',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF800000),
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/reset-password', arguments: role);
                                    },
                                    child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  icon: Icon(Icons.login, color: Colors.white),
                                  label: _isLoading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: Color(0xFF800000),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    elevation: 2,
                                    overlayColor: Color(0xFF0D1333),
                                  ),
                                  onPressed: _isLoading ? null : _login,
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                                if (role == 'vendor') ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF800000)),
                                    label: const Text('Don\'t have an account? Register', style: TextStyle(color: Color(0xFF800000), fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      side: const BorderSide(color: Color(0xFF800000)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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