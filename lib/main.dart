import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/vendor/edit_profile_screen.dart';
import 'screens/supplier/edit_profile_screen.dart';
import 'screens/vendor/settings_screen.dart';
import 'screens/supplier/settings_screen.dart';
import 'screens/vendor/product_analytics_screen.dart';
import 'screens/vendor/suggested_order_details_screen.dart';
import 'models/order.dart';
import 'screens/vendor/orders_screen.dart';
import 'screens/vendor/detailed_reports_screen.dart';
import 'models/order.dart' as order_model;
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const VendorSyncApp(),
    ),
  );
}

class VendorSyncApp extends StatelessWidget {
  const VendorSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VendorSync',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
            '/vendor-order-details': (context) => const VendorOrderDetailsScreen(),
            '/vendor-notifications': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return VendorNotificationsScreen(vendorEmail: email ?? '');
            },
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
            '/vendor-settings': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return VendorSettingsScreen(vendorEmail: email ?? '');
            },
            '/supplier-dashboard': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierDashboardScreen(supplierEmail: email ?? '');
            },
            '/supplier-order-details': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final order = args?['order'] as order_model.Order?;
              final supplierEmail = args?['supplierEmail'] as String? ?? '';
              return SupplierOrderDetailsScreen(supplierEmail: supplierEmail);
            },
            '/supplier-delivery-schedule': (context) => const SupplierDeliveryScheduleScreen(),
            '/supplier-notifications': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierNotificationsScreen(supplierEmail: email ?? '');
            },
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
            '/supplier-settings': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierSettingsScreen(supplierEmail: email ?? '');
            },
            '/vendor-suppliers': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return SuppliersListScreen(vendorEmail: email ?? '');
            },
            '/vendor-threshold-management': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return ThresholdManagementScreen(vendorEmail: email ?? '');
            },
            '/vendor-orders': (context) {
              final email = ModalRoute.of(context)?.settings.arguments as String?;
              return OrdersScreen(vendorEmail: email ?? '');
            },
            '/vendor-detailed-reports': (context) {
              final productName = ModalRoute.of(context)?.settings.arguments as String?;
              return DetailedReportsScreen(productName: productName ?? '');
            },
            '/vendor-quick-order': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return QuickOrderScreen(
                vendorEmail: args?['vendorEmail'] ?? '',
                productName: args?['productName'] ?? '',
                suggestedQuantity: args?['suggestedQuantity'] ?? 0,
                supplierEmail: args?['supplierEmail'],
                supplierName: args?['supplierName'],
              );
            },
            '/vendor-product-analytics': (context) {
              final productName = ModalRoute.of(context)?.settings.arguments as String?;
              return ProductAnalyticsScreen(productName: productName ?? '');
            },
            '/vendor-suggested-order-details': (context) {
              final stockItem = ModalRoute.of(context)?.settings.arguments as StockItem?;
              return SuggestedOrderDetailsScreen(stockItem: stockItem!);
            },
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF43E97B),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF43E97B),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      cardColor: const Color(0xFF1E1E1E),
      dialogBackgroundColor: const Color(0xFF1E1E1E),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }
}
