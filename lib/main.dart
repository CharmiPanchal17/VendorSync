import 'package:flutter/material.dart';
import 'screens.dart';

void main() {
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
        '/register-suppliers': (context) => const RegisterSuppliersScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/vendor-dashboard': (context) => const VendorDashboardScreen(),
        '/vendor-create-order': (context) => const CreateOrderScreen(),
        '/vendor-order-details': (context) => const VendorOrderDetailsScreen(),
        '/vendor-notifications': (context) => const VendorNotificationsScreen(),
        '/vendor-profile': (context) => const VendorProfileScreen(),
        '/supplier-dashboard': (context) => const SupplierDashboardScreen(),
        '/supplier-order-details': (context) => const SupplierOrderDetailsScreen(),
        '/supplier-delivery-schedule': (context) => const SupplierDeliveryScheduleScreen(),
        '/supplier-notifications': (context) => const SupplierNotificationsScreen(),
        '/supplier-profile': (context) => const SupplierProfileScreen(),
        '/create-order': (context) => CreateOrderScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
