import 'package:flutter/material.dart';
import '../constants/colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF2D2D2D) : lightCyan,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Upper section: Logo and words
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: maroon.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'VendorSync',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: maroon,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your intelligent Vendor-to-Supplier \n Management System',
                        style: TextStyle(
                          fontSize: 20,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          height: 1.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // Rainbow divider
              SizedBox(
                height: 128,
                width: double.infinity,
                child: CustomPaint(
                  painter: RainbowDividerPainter(),
                ),
              ),
              // Lower section: Buttons
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildActionButton(
                                  'Vendor Register',
                                  Icons.store,
                                  maroon,
                                  () => Navigator.of(context).pushNamed('/register'),
                                ),
                                const SizedBox(height: 24),
                                _buildActionButton(
                                  'Supplier Register',
                                  Icons.local_shipping,
                                  maroon,
                                  () => Navigator.of(context).pushNamed('/register-supplier'),
                                ),
                                const SizedBox(height: 24),
                                _buildActionButton(
                                  'Login as Vendor',
                                  Icons.login,
                                  Colors.blue,
                                  () => Navigator.of(context).pushNamed('/login', arguments: 'vendor'),
                                ),
                                const SizedBox(height: 24),
                                _buildActionButton(
                                  'Login as Supplier',
                                  Icons.login,
                                  Colors.blue,
                                  () => Navigator.of(context).pushNamed('/login', arguments: 'supplier'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: maroon, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: maroon,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RainbowDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rainbow = [
      Colors.white,
      maroon,
      Colors.blue,
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    final path = Path();
    // Draw a bigger wavy curve
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.15, size.height * 0.1,
      size.width * 0.85, size.height * 1.3,
      size.width, size.height * 0.7,
    );
    // White
    paint.color = rainbow[0];
    paint.strokeWidth = 20;
    canvas.drawPath(path, paint);
    // Maroon
    paint.color = rainbow[1];
    paint.strokeWidth = 20;
    canvas.drawPath(path.shift(const Offset(0, 8)), paint);
    // Blue (thinner)
    paint.color = rainbow[2];
    paint.strokeWidth = 12;
    canvas.drawPath(path.shift(const Offset(0, 16)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 