import 'package:flutter/material.dart';
import 'screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/vendor/settings_screen.dart';
import 'screens/supplier/settings_screen.dart';
import 'screens/vendor/product_analytics_screen.dart';
import 'screens/vendor/suggested_order_details_screen.dart';
import 'models/order.dart';
import 'models/order.dart' as order_model;
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final storage = FlutterSecureStorage();
  String? userEmail = await storage.read(key: 'userEmail');
  String? loginTimestampStr = await storage.read(key: 'loginTimestamp');
  bool isSessionValid = false;
  if (loginTimestampStr != null) {
    final loginTimestamp = DateTime.fromMillisecondsSinceEpoch(
      int.parse(loginTimestampStr),
    );
    final now = DateTime.now();
    if (now.difference(loginTimestamp).inDays < 6) {
      isSessionValid = true;
    } else {
      // Session expired, clear storage
      await storage.delete(key: 'userEmail');
      await storage.delete(key: 'loginTimestamp');
    }
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: VendorSyncApp(
        isSessionValid: isSessionValid,
        userEmail: userEmail,
      ),
    ),
  );
}

class VendorSyncApp extends StatelessWidget {
  final bool isSessionValid;
  final String? userEmail;
  const VendorSyncApp({super.key, this.isSessionValid = false, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VendorSync',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: isSessionValid ? '/auto-login' : '/splash',
          routes: {
            '/auto-login': (context) => _AutoLoginScreen(userEmail: userEmail),
            '/splash': (context) => const SplashScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/register-supplier': (context) => const RegisterSupplierScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/role-selection': (context) => const RoleSelectionScreen(),
            '/vendor-dashboard': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return VendorDashboardScreen(vendorEmail: email ?? '');
            },
            '/vendor-order-details': (context) =>
                const VendorOrderDetailsScreen(),
            '/vendor-notifications': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return VendorNotificationsScreen(vendorEmail: email ?? '');
            },
            '/vendor-profile': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return VendorProfileScreen(vendorEmail: email ?? '');
            },
            '/vendor-edit-profile': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final email = args?['email'] as String? ?? '';
              final vendorData =
                  args?['vendorData'] as Map<String, dynamic>? ?? {};
              return EditVendorProfileScreen(
                vendorEmail: email,
                vendorData: vendorData,
              );
            },
            '/vendor-settings': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return VendorSettingsScreen(vendorEmail: email ?? '');
            },
            '/supplier-dashboard': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierDashboardScreen(supplierEmail: email ?? '');
            },
            '/supplier-order-details': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final order = args?['order'] as order_model.Order?;
              final supplierEmail = args?['supplierEmail'] as String? ?? '';
              return SupplierOrderDetailsScreen(supplierEmail: supplierEmail);
            },
            '/supplier-delivery-schedule': (context) =>
                const SupplierDeliveryScheduleScreen(),
            '/supplier-notifications': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierNotificationsScreen(supplierEmail: email ?? '');
            },
            '/supplier-profile': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierProfileScreen(supplierEmail: email ?? '');
            },
            '/supplier-edit-profile': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final email = args?['email'] as String? ?? '';
              final supplierData =
                  args?['supplierData'] as Map<String, dynamic>? ?? {};
              return EditSupplierProfileScreen(
                supplierEmail: email,
                supplierData: supplierData,
              );
            },
            '/supplier-settings': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return SupplierSettingsScreen(supplierEmail: email ?? '');
            },
            '/vendor-suppliers': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return SuppliersListScreen(vendorEmail: email ?? '');
            },
            '/vendor-threshold-management': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              String vendorEmail = '';
              String? productName;
              int? thresholdLevel;

              if (args is String) {
                vendorEmail = args;
              } else if (args is Map<String, dynamic>) {
                vendorEmail = args['vendorEmail'] ?? '';
                productName = args['productName'];
                thresholdLevel = args['thresholdLevel'];
              }

              return ThresholdManagementScreen(
                vendorEmail: vendorEmail,
                productName: productName,
                thresholdLevel: thresholdLevel,
              );
            },
            '/vendor-orders': (context) {
              final email =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return OrdersScreen(vendorEmail: email ?? '');
            },
            '/vendor-detailed-reports': (context) {
              final productName =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return DetailedReportsScreen(productName: productName ?? '');
            },
            '/vendor-quick-order': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              return QuickOrderScreen(
                vendorEmail: args?['vendorEmail'] ?? '',
                productName: args?['productName'] ?? '',
                suggestedQuantity: args?['suggestedQuantity'] ?? 0,
                supplierEmail: args?['supplierEmail'],
                supplierName: args?['supplierName'],
              );
            },
            '/vendor-product-analytics': (context) {
              final productName =
                  ModalRoute.of(context)?.settings.arguments as String?;
              return ProductAnalyticsScreen(productName: productName ?? '');
            },
            '/vendor-suggested-order-details': (context) {
              final stockItem =
                  ModalRoute.of(context)?.settings.arguments as StockItem?;
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
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1E1E1E)),
      dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
    );
  }
}

class _AutoLoginScreen extends StatelessWidget {
  final String? userEmail;
  const _AutoLoginScreen({this.userEmail});

  Future<String?> _getUserRole(String? email) async {
    if (email == null) return null;
    final vendorQuery = await FirebaseFirestore.instance
        .collection('vendors')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (vendorQuery.docs.isNotEmpty) return 'vendor';
    final supplierQuery = await FirebaseFirestore.instance
        .collection('suppliers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (supplierQuery.docs.isNotEmpty) return 'supplier';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          final role = snapshot.data;
          if (role == 'vendor') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(
                context,
              ).pushReplacementNamed('/vendor-dashboard', arguments: userEmail);
            });
          } else if (role == 'supplier') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(
                '/supplier-dashboard',
                arguments: userEmail,
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/login');
            });
          }
        }
        return const SplashScreen();
      },
    );
  }
}
