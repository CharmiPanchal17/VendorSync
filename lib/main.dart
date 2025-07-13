import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const VendorSyncApp());
}

class VendorSyncApp extends StatelessWidget {
  const VendorSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendorSync',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
          surface: Colors.white,
          primary: Color(0xFF8B0000), // Maroon
          onPrimary: Colors.white,    // Button text color
        ),
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8B0000),
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register-supplier': (context) => const RegisterSupplierScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/vendor-dashboard': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return VendorDashboardScreen(vendorEmail: email ?? '');
        },
        '/vendor-create-order': (context) => const VendorCreateOrderScreen(vendorEmail: ''),
        '/vendor-order-details': (context) => const VendorOrderDetailsScreen(),
        '/vendor-notifications': (context) => const VendorNotificationsScreen(),
        '/vendor-profile': (context) => const VendorProfileScreen(),
        '/supplier-dashboard': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return SupplierDashboardScreen(supplierEmail: email ?? '');
        },
        '/supplier-order-details': (context) => const SupplierOrderDetailsScreen(),
        '/supplier-delivery-schedule': (context) => const SupplierDeliveryScheduleScreen(),
        '/supplier-notifications': (context) => const SupplierNotificationsScreen(),
        '/supplier-profile': (context) => const SupplierProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
