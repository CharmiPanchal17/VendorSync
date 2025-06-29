import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/vendor/edit_profile_screen.dart';
import 'screens/supplier/edit_profile_screen.dart';

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
        '/vendor-profile': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return VendorProfileScreen(vendorEmail: email ?? '');
        },
        '/vendor-edit-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final email = args?['email'] as String? ?? '';
          final vendorData = args?['vendorData'] as Map<String, dynamic>? ?? {};
          return EditVendorProfileScreen(vendorEmail: email, vendorData: vendorData);
        },
        '/supplier-dashboard': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return SupplierDashboardScreen(supplierEmail: email ?? '');
        },
        '/supplier-order-details': (context) => const SupplierOrderDetailsScreen(),
        '/supplier-delivery-schedule': (context) => const SupplierDeliveryScheduleScreen(),
        '/supplier-notifications': (context) => const SupplierNotificationsScreen(),
        '/supplier-profile': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return SupplierProfileScreen(supplierEmail: email ?? '');
        },
        '/supplier-edit-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final email = args?['email'] as String? ?? '';
          final supplierData = args?['supplierData'] as Map<String, dynamic>? ?? {};
          return EditSupplierProfileScreen(supplierEmail: email, supplierData: supplierData);
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
