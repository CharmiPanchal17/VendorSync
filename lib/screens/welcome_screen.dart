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

  final List<String> _welcomeWords = ['Welcome', 'to', 'VendorSync'];
  int _visibleWordCount = 1;
  String _displayedText = '';
  int _selectedRegisterIndex = -1;

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
    _typeWriterEffect();
  }

  Future<void> _typeWriterEffect() async {
    const String fullText = 'Welcome to VendorSync';
    for (int i = 1; i <= fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) {
        setState(() => _displayedText = fullText.substring(0, i));
        print('Typewriter: 			' + _displayedText);
      }
    }
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
                            _displayedText.isNotEmpty ? _displayedText : 'Welcome to VendorSync',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF800000),
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
                          FilledButton(
                            child: const Text('Register As', style: TextStyle(fontSize: 18)),
                            style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
                              backgroundColor: MaterialStateProperty.all(const Color(0xFF800000)), // Maroon
                              foregroundColor: MaterialStateProperty.all(Colors.white),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                              elevation: MaterialStateProperty.all(2),
                              overlayColor: MaterialStateProperty.all(Color(0xFF0D1333)),
                            ),
                            onPressed: null, // No action, just a label
                          ),
                          const SizedBox(height: 16),
                          // Replace the Row with two buttons with a segmented control
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedRegisterIndex = 0);
                                    Navigator.of(context).pushNamed('/register');
                                  },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _selectedRegisterIndex == 0 ? const Color(0xFF800000) : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(_selectedRegisterIndex == 0 ? 20 : 12),
                                        bottomLeft: Radius.circular(_selectedRegisterIndex == 0 ? 20 : 12),
                                        topRight: Radius.circular(_selectedRegisterIndex == 0 ? 4 : 0),
                                        bottomRight: Radius.circular(_selectedRegisterIndex == 0 ? 4 : 0),
                                      ),
                                      border: Border.all(color: const Color(0xFF800000), width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Vendor',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRegisterIndex == 0 ? Colors.white : const Color(0xFF800000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedRegisterIndex = 1);
                                    Navigator.of(context).pushNamed('/register-supplier');
                                  },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _selectedRegisterIndex == 1 ? const Color(0xFF800000) : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(_selectedRegisterIndex == 1 ? 20 : 12),
                                        bottomRight: Radius.circular(_selectedRegisterIndex == 1 ? 20 : 12),
                                        topLeft: Radius.circular(_selectedRegisterIndex == 1 ? 4 : 0),
                                        bottomLeft: Radius.circular(_selectedRegisterIndex == 1 ? 4 : 0),
                                      ),
                                      border: Border.all(color: const Color(0xFF800000), width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Supplier',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedRegisterIndex == 1 ? Colors.white : const Color(0xFF800000),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
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