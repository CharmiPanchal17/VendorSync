import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the colors based on the screenshot
    const Color backgroundColor = Color(0xFFB2FFFF); // Light cyan/sky blue
    const Color maroonColor = Color(0xFF8B0000); // Deep maroon

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: maroonColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'VendorSync',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: maroonColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your all-in-one Vendor-to-Supplier\nManagement System',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Oval image from assets
                ClipOval(
                  child: Image.asset(
                    'assets/supermarket.jpg', // Updated filename
                    width: 220,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 36),
                // Vendor Register Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/register'),
                      child: const Text('🔗 Vendor Register'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Supplier Register Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/register-supplier'),
                      child: const Text('📦 Supplier Register'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 