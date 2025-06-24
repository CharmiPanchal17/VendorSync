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
        colorSchemeSeed: Colors.blue,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/vendor-dashboard': (context) => const VendorDashboardScreen(),
        '/vendor-create-order': (context) => const VendorCreateOrderScreen(),
        '/vendor-order-details': (context) => const VendorOrderDetailsScreen(),
        '/vendor-notifications': (context) => const VendorNotificationsScreen(),
        '/vendor-profile': (context) => const VendorProfileScreen(),
        '/supplier-dashboard': (context) => const SupplierDashboardScreen(),
        '/supplier-order-details': (context) => const SupplierOrderDetailsScreen(),
        '/supplier-delivery-schedule': (context) => const SupplierDeliveryScheduleScreen(),
        '/supplier-notifications': (context) => const SupplierNotificationsScreen(),
        '/supplier-profile': (context) => const SupplierProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
