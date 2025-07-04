import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          // Solid light cyan background
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            'Welcome to VendorSync',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD50060),
                              fontSize: 44,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your all-in-one Vendor-to-Supplier Management System',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Color(0xFF333333), fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                            child: Center(
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/welcome.jpeg',
                                  width: 220,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    child: const Text('Vendor Register', style: TextStyle(fontSize: 18)),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      backgroundColor: const Color(0xFFD50060), // Magenta
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                      elevation: 2,
                                      overlayColor: Color(0xFF0D1333), // Dark blue on press
                                    ),
                                    onPressed: () => Navigator.of(context).pushNamed('/register'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    child: const Text('Supplier Register', style: TextStyle(fontSize: 18)),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      backgroundColor: const Color(0xFFD50060), // Magenta
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                      elevation: 2,
                                      overlayColor: Color(0xFF0D1333), // Dark blue on press
                                    ),
                                    onPressed: () => Navigator.of(context).pushNamed('/register-supplier'),
                                  ),
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
          ),
        ],
      ),
    );
  }
} 