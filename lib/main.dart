import 'package:flutter/material.dart';
import 'package:vendorsync/firebase_options.dart';
import 'package:vendorsync/screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/connectivity_service.dart';
import 'screens/role_selection_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const VendorSyncApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VendorSyncApp());
}

class VendorSyncApp extends StatefulWidget {
  const VendorSyncApp({super.key});

  @override
  State<VendorSyncApp> createState() => _VendorSyncAppState();
}

class _VendorSyncAppState extends State<VendorSyncApp> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    // Initialize connectivity monitoring after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.initializeConnectivityMonitoring(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VendorSync',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register-vendor': (context) => const RegisterScreen(),
        '/register-supplier': (context) => const RegisterSupplierScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/offline': (context) => const OfflineScreen(),
        '/vendor-dashboard': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return VendorDashboardScreen(vendorEmail: email ?? '');
        },
        '/vendor-create-order': (context) =>
            const VendorCreateOrderScreen(vendorEmail: ''),
        '/vendor-order-details': (context) => const VendorOrderDetailsScreen(),
        '/vendor-notifications': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return VendorNotificationsScreen(vendorEmail: email ?? '');
        },
        '/vendor-profile': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return VendorProfileScreen(vendorEmail: email ?? '');
        },
        '/supplier-dashboard': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return SupplierDashboardScreen(supplierEmail: email ?? '');
        },
        '/supplier-order-details': (context) =>
            const SupplierOrderDetailsScreen(),
        '/supplier-delivery-schedule': (context) =>
            const SupplierDeliveryScheduleScreen(),
        '/supplier-notifications': (context) =>
            const SupplierNotificationsScreen(),
        '/supplier-profile': (context) => const SupplierProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
