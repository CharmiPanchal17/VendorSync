import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../mock_data/mock_orders.dart';
import '../../models/order.dart' as order_model;
import '../../services/notification_service.dart';
import '../../services/delivery_tracking_service.dart';
import '../../services/auto_reorder_service.dart';
import '../../widgets/auto_reorder_dashboard.dart';
import 'suppliers_list_screen.dart';
import 'settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'stock_management_screen.dart';
import 'analytics_screen.dart';
import 'create_order_screen.dart';
import '../../services/auth_service.dart';
import 'real_time_sales_screen.dart';
import 'spreadsheet_upload_screen.dart';
import '../../services/sales_service.dart';
import 'report_screen.dart';
import 'below_threshold_screen.dart';


// Rename color constant to avoid export conflicts
const maroonVendor = Color(0xFF800000);
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key, this.vendorEmail = 'vendor@example.com'});
  final String vendorEmail;

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  String selectedStatus = 'All';
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  String? vendorName;

  List<Map<String, dynamic>> draftOrders = [];


  @override
  void initState() {
    super.initState();
    _fetchVendorName();
    _checkAndLoadDraftOrders();

  }

  Future<void> _fetchVendorName() async {
    try {
      final query = await FirebaseFirestore.instance
        .collection('vendors')
        .where('email', isEqualTo: widget.vendorEmail)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        setState(() {
          vendorName = query.docs.first['name'] ?? 'Vendor';
        });
      } else {
        setState(() {
          vendorName = 'Vendor';
        });
      }
    } catch (e) {
      print('Error fetching vendor name: $e');
      setState(() {
        vendorName = 'Vendor';
      });
   
  Future<void> _checkAndLoadDraftOrders() async {
    await SalesService.checkAndCreateDraftOrders(widget.vendorEmail);
    final drafts = await SalesService.getDraftOrders(widget.vendorEmail);
    setState(() {
      draftOrders = drafts;
    });


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFAFFFFF),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF3D3D3D)
                      : maroonVendor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(Icons.store, size: 40, color: isDark ? Colors.white : maroonVendor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vendorName ?? 'Vendor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your account',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.vendorEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () => Navigator.pop(context),
                      isSelected: true,
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.shopping_cart,
                      title: 'Orders',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/vendor-orders', arguments: widget.vendorEmail);
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                      badge: _pendingOrdersCount > 0 ? _pendingOrdersCount.toString() : null,
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.add_shopping_cart,
                      title: 'Create Initial Order',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => CreateOrderScreen(vendorEmail: widget.vendorEmail),
                        ));
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.inventory,
                      title: 'Stock Management',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => StockManagementScreen(vendorEmail: widget.vendorEmail),
                        ));
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(

                      icon: Icons.auto_awesome,
                      title: 'Auto Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/auto-settings', arguments: widget.vendorEmail);
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.bar_chart,
                      title: 'Monitor Stock',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/monitor-stock', arguments: widget.vendorEmail);
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.warning,
                      title: 'Below Threshold',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/below-threshold', arguments: widget.vendorEmail);

                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.analytics,
                      title: 'Analytics',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AnalyticsScreen(vendorEmail: widget.vendorEmail),
                        ));
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.list,
                      title: 'My Suppliers',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SuppliersListScreen(vendorEmail: widget.vendorEmail),
                        ));
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/vendor-notifications', arguments: widget.vendorEmail);
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/vendor-profile', arguments: widget.vendorEmail);
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => VendorSettingsScreen(vendorEmail: widget.vendorEmail),
                        ));
                      },
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'Logout',
                              style: TextStyle(
                                color: isDark ? colorScheme.onSurface : Colors.black,
                              ),
                            ),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final storage = const FlutterSecureStorage();
                          await storage.delete(key: 'userEmail');
                          await storage.delete(key: 'loginTimestamp');
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      isLogout: true,
                      textColor: isDark ? Colors.white : Color(0xFF800000),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Vendor Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? colorScheme.onSurface : maroonVendor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'View Stock Report',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ReportScreen(vendorEmail: widget.vendorEmail),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await _checkAndLoadDraftOrders();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dashboard refreshed.'), backgroundColor: maroonVendor),
              );
            },
          ),
          // Notification Bell with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushNamed('/vendor-notifications', arguments: widget.vendorEmail);
                },
              ),
              // Notification Badge
              Positioned(
                right: 8,
                top: 8,
                child: StreamBuilder<int>(
                  stream: NotificationService.getUnreadNotificationCount(widget.vendorEmail),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    if (unreadCount > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                : [maroonVendor, maroonVendor.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : const Color(0xFFAFFFFF),
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)],
                )
              : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Welcome Card with modern design
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                child: Padding(
                      padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark 
                                  ? [colorScheme.primary, colorScheme.secondary]
                                  : [maroonVendor, maroonVendor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.store, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                Text(
                                  vendorName != null
                                      ? 'Welcome back, $vendorName!'
                                      : 'Welcome to VendorSync',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? colorScheme.onSurface : maroonVendor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage your orders and suppliers efficiently',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? colorScheme.onSurface.withOpacity(0.7) : maroonVendor.withOpacity(0.7),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
                  
                  // Calendar and Status Filter Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? colorScheme.primary.withOpacity(0.2) : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today, 
                                  color: isDark ? colorScheme.primary : maroonVendor, 
                                  size: 20
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Calendar & Filters',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? colorScheme.onSurface : maroonVendor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<DateTime>>(
                            stream: _getConfirmedOrderDates(),
                            builder: (context, snapshot) {
                              final confirmedDates = snapshot.data ?? [];
                              
                              return TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: focusedDay,
                                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                                onDaySelected: (selected, focused) {
                                  setState(() {
                                    selectedDay = selected;
                                    focusedDay = focused;
                                  });
                                },
                                eventLoader: (day) {
                                  // Check if this day has any confirmed orders
                                  final hasConfirmedOrder = confirmedDates.any((date) => 
                                    isSameDay(date, day)
                                  );
                                  return hasConfirmedOrder ? ['Confirmed Order'] : [];
                                },
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark 
                                        ? [colorScheme.primary, colorScheme.secondary]
                                        : [maroonVendor, maroonVendor.withOpacity(0.8)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: isDark ? colorScheme.primary : Colors.blue.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: isDark ? Colors.red.shade300 : Colors.red
                                  ),
                                  markerDecoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Calendar Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confirmed Orders',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Summary Cards
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.primary.withOpacity(0.2) : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.analytics, 
                              color: isDark ? colorScheme.primary : maroonVendor, 
                              size: 20
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? colorScheme.onSurface : maroonVendor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildVendorStatCard(
                              icon: Icons.inventory,
                              title: 'Total Orders',
                              value: _buildVendorTotalOrdersCount(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildVendorStatCard(
                              icon: Icons.pending,
                              title: 'Pending',
                              value: _buildVendorPendingOrdersCount(),
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildVendorStatCard(
                              icon: Icons.check_circle,
                              title: 'Confirmed',
                              value: _buildVendorConfirmedOrdersCount(),
                              color: maroonVendor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildVendorStatCard(
                              icon: Icons.local_shipping,
                              title: 'Delivered',
                              value: _buildVendorDeliveredOrdersCount(),
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Auto-Reorder Dashboard
                  AutoReorderDashboard(vendorEmail: widget.vendorEmail),
                  
                  const SizedBox(height: 24),
                  
                  // Status Filter
                  Text(
                    'Filter Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colorScheme.onSurface : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusButton('All', Colors.grey),
                        const SizedBox(width: 12),
                        _buildStatusButton('Pending', Colors.orange),
                        const SizedBox(width: 12),
                        _buildStatusButton('Confirmed', Colors.blue),
                        const SizedBox(width: 12),
                        _buildStatusButton('Delivered', maroonVendor),
                        const SizedBox(width: 12),
                        _buildStatusButton('Pending Approval', Colors.purple),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Orders Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.inventory, color: Colors.blue.shade700, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Color(0xFF800000),
                        ),
                  ),
                ],
              ),
                  const SizedBox(height: 16),
                  
                  // Orders List
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('vendorEmail', isEqualTo: widget.vendorEmail)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Loading orders...'),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Error loading orders',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final orders = snapshot.data?.docs ?? [];
                      
                      // Sort orders by createdAt in descending order (newest first)
                      orders.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aCreatedAt = aData['createdAt'] as Timestamp?;
                        final bCreatedAt = bData['createdAt'] as Timestamp?;
                        
                        if (aCreatedAt == null && bCreatedAt == null) return 0;
                        if (aCreatedAt == null) return 1;
                        if (bCreatedAt == null) return -1;
                        
                        return bCreatedAt.compareTo(aCreatedAt); // Descending order
                      });
                      
                      if (orders.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.inventory_outlined, color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Orders Yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first order to get started',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final filteredOrders = orders.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] as String? ?? 'Pending';
                        return selectedStatus == 'All' || status == selectedStatus;
                      }).toList();
                      
                      if (filteredOrders.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.filter_list, color: Colors.grey.shade400, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                'No $selectedStatus orders',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
              const SizedBox(height: 8),
                              Text(
                                'Try changing the filter or create a new order',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                          final doc = filteredOrders[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final orderId = doc.id;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                      child: ListTile(
                              contentPadding: const EdgeInsets.all(20),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [maroonVendor, maroonVendor.withOpacity(0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.inventory, color: Colors.white, size: 24),
                              ),
                              title: Text(
                                data['productName'] ?? 'Unknown Product',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supplier: ${data['supplierName'] ?? 'Unknown Supplier'}',
                                    style: TextStyle(
                                      color: isDark ? colorScheme.onSurface.withOpacity(0.9) : Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Quantity: ${data['quantity'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: isDark ? colorScheme.onSurface.withOpacity(0.9) : Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (data['preferredDeliveryDate'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Delivery: ${DateFormat.yMMMd().format((data['preferredDeliveryDate'] as Timestamp).toDate())}',
                                      style: TextStyle(
                                        color: isDark ? colorScheme.onSurface.withOpacity(0.9) : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Container(
                                child: (data['status'] == 'Pending Approval')
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          elevation: 2,
                                        ),
                                        onPressed: () => _showApproveConfirmation(orderId),
                                        child: const Text(
                                          'Approve',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _statusColor(data['status'] ?? 'Pending'),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _statusBorderColor(data['status'] ?? 'Pending'),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          data['status'] ?? 'Pending',
                                          style: TextStyle(
                                            color: _statusTextColor(data['status'] ?? 'Pending'),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                              ),
                        onTap: () {
                                // Create an order object for navigation
                                final orderData = order_model.Order(
                                  id: orderId,
                                  productName: data['productName'] ?? 'Unknown Product',
                                  supplierName: data['supplierName'] ?? 'Unknown Supplier',
                                  supplierEmail: data['supplierEmail'] ?? 'unknown@example.com',
                                  quantity: data['quantity'] ?? 0,
                                  status: data['status'] ?? 'Pending',
                                  preferredDeliveryDate: data['preferredDeliveryDate'] != null 
                                      ? (data['preferredDeliveryDate'] as Timestamp).toDate()
                                      : DateTime.now(),
                                );
                                Navigator.of(context).pushNamed('/vendor-order-details', arguments: orderData);
                        },
                      ),
                    );
                  },
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPress
          _showUpdateStockOptions(context);

        },
        icon: const Icon(Icons.inventory),
        label: const Text('Update Stock'),
        backgroundColor: maroonVendor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusButton(String status, Color color) {
    final isSelected = selectedStatus == status;
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.transparent : Colors.white,
          foregroundColor: isSelected ? Colors.white : color,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide(
            color: isSelected ? Colors.transparent : color,
            width: 2,
          ),
          minimumSize: const Size(100, 40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () {
          setState(() {
            selectedStatus = status;
          });
        },
        child: Text(
          status,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade100;
      case 'Confirmed':
        return Colors.blue.shade100;
      case 'Delivered':
        return maroonVendor.withOpacity(0.08);
      case 'Pending Approval':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusBorderColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Delivered':
        return maroonVendor;
      case 'Pending Approval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Delivered':
        return maroonVendor;
      case 'Pending Approval':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isLogout = false,
    Color? textColor,
    Color? iconColor,
    String? badge,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(isDark ? 0.15 : 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: Colors.white.withOpacity(isDark ? 0.25 : 0.3), 
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: iconColor ?? (isSelected 
              ? (isDark ? Colors.white : Color(0xFF800000))
              : (isDark ? Colors.white : Color(0xFF800000))),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? (isSelected 
                ? (isDark ? Colors.white : Color(0xFF800000))
                : (isDark ? Colors.white : Color(0xFF800000))),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVendorStatCard({
    required IconData icon,
    required String title,
    required Widget value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          value,
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorTotalOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            '...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        );
      },
    );
  }

  Widget _buildVendorPendingOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            '...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        );
      },
    );
  }

  Widget _buildVendorConfirmedOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .where('status', isEqualTo: 'Confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            '...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        );
      },
    );
  }

  Widget _buildVendorDeliveredOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .where('status', isEqualTo: 'Delivered')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            '...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        );
      },
    );
  }

  Future<void> _showApproveConfirmation(String orderId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Confirm'),
          ],
        ),
        content: const Text('Are you sure you want to approve the delivery? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _approveOrder(orderId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveOrder(String orderId) async {
    try {
      // First, get the order details before updating
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data()!;
      final productName = orderData['productName'] as String;
      final quantity = orderData['quantity'] as int;
      final supplierName = orderData['supplierName'] as String;
      final supplierEmail = orderData['supplierEmail'] as String;
      final unitPrice = orderData['unitPrice'] as double?;
      
      // Update the order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'Delivered',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update stock management data automatically
      await DeliveryTrackingService.recordDelivery(
        orderId: orderId,
        productName: productName,
        quantity: quantity,
        supplierName: supplierName,
        supplierEmail: supplierEmail,
        deliveryDate: DateTime.now(),
        unitPrice: unitPrice,
        notes: 'Approved by vendor',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order approved successfully! Stock has been updated.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve order: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showUpdateStockOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: const Text('How would you like to update the stock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonVendor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RealTimeSalesScreen(
                  vendorEmail: widget.vendorEmail,
                ),
              ));
            },
            child: const Text('Real-time Sales'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonVendor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showSpreadsheetUpload(context);
            },
            child: const Text('Upload Spreadsheet'),
          ),
        ],
      ),
    );
  }

  void _showSpreadsheetUpload(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SpreadsheetUploadScreen(
        vendorEmail: widget.vendorEmail,
      ),
    ));
  }

  Future<void> _updateStockAfterDelivery(String productName, int quantity, String supplierName, String supplierEmail, double? unitPrice, String orderId) async {
    try {
      // Create a new delivery record
      final deliveryRecord = order_model.DeliveryRecord(
        id: 'del_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        productName: productName,
        quantity: quantity,
        supplierName: supplierName,
        supplierEmail: supplierEmail,
        deliveryDate: DateTime.now(),
        unitPrice: unitPrice,
        notes: 'Delivered and approved by vendor',
        status: 'Completed',
        vendorEmail: widget.vendorEmail,
      );

      // Find and update the corresponding stock item
      final stockIndex = mockStockItems.indexWhere((item) => item.productName == productName);
      
      if (stockIndex != -1) {
        final currentStockItem = mockStockItems[stockIndex];
        final updatedDeliveryHistory = List<order_model.DeliveryRecord>.from(currentStockItem.deliveryHistory)
          ..add(deliveryRecord);
        
        // Calculate new average unit price
        final totalPrice = updatedDeliveryHistory
            .where((record) => record.unitPrice != null)
            .fold(0.0, (sum, record) => sum + (record.unitPrice ?? 0));
        final totalDeliveries = updatedDeliveryHistory.length;
        final newAveragePrice = totalDeliveries > 0 ? totalPrice / totalDeliveries : unitPrice;

        // Calculate new total stock: quantity delivered + current stock at time of delivery
        final newCurrentStock = currentStockItem.currentStock + quantity;
        final newTotalStock = quantity + currentStockItem.currentStock; // Total = delivered + current stock at delivery time

        // Update the stock item
        mockStockItems[stockIndex] = order_model.StockItem(
          id: currentStockItem.id,
          productName: currentStockItem.productName,
          currentStock: newCurrentStock,
          minimumStock: currentStockItem.minimumStock,
          maximumStock: newTotalStock, // Update total stock with new calculation
          deliveryHistory: updatedDeliveryHistory,
          primarySupplier: currentStockItem.primarySupplier,
          primarySupplierEmail: currentStockItem.primarySupplierEmail,
          firstDeliveryDate: currentStockItem.firstDeliveryDate ?? DateTime.now(),
          lastDeliveryDate: DateTime.now(),
          autoOrderEnabled: currentStockItem.autoOrderEnabled,
          averageUnitPrice: newAveragePrice,
          vendorEmail: widget.vendorEmail,
        );

        // If using Firestore, you would also update the stock collection here
        // For now, we're using mock data, so the UI will update when the stock management page is refreshed
      } else {
        // If stock item doesn't exist, create a new one
        final newStockItem = order_model.StockItem(
          id: 'stock_${DateTime.now().millisecondsSinceEpoch}',
          productName: productName,
          currentStock: quantity,
          minimumStock: 20, // Default minimum stock
          maximumStock: quantity, // Total stock = quantity delivered (since no previous stock)
          deliveryHistory: [deliveryRecord],
          primarySupplier: supplierName,
          primarySupplierEmail: supplierEmail,
          firstDeliveryDate: DateTime.now(),
          lastDeliveryDate: DateTime.now(),
          autoOrderEnabled: false,
          averageUnitPrice: unitPrice,
          vendorEmail: widget.vendorEmail,
        );
        
        mockStockItems.add(newStockItem);
      }
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  // Method to get confirmed order dates for the calendar
  Stream<List<DateTime>> _getConfirmedOrderDates() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorEmail', isEqualTo: widget.vendorEmail)
        .where('status', isEqualTo: 'Confirmed')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final deliveryDate = data['preferredDeliveryDate'] as Timestamp?;
            return deliveryDate?.toDate() ?? DateTime.now();
          }).toList();
        });
  }

  Widget _buildDraftOrdersSection(bool isDark) {
    if (draftOrders.isEmpty) return const SizedBox.shrink();
    return Card(
      color: isDark ? Colors.white10 : Colors.white,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: maroonVendor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: maroonVendor),
                const SizedBox(width: 8),
                Text('Draft Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            ...draftOrders.map((order) => _buildDraftOrderCard(order, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftOrderCard(Map<String, dynamic> order, bool isDark) {
    final analysis = order['analysis'] as Map<String, dynamic>?;
    final TextEditingController qtyController = TextEditingController(text: order['suggestedQuantity'].toString());
    Color getPriorityColor(String? priority) {
      switch (priority) {
        case 'High':
          return Colors.red;
        case 'Medium':
          return Colors.orange;
        case 'Low':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }
    return Card(
      color: isDark ? Colors.white24 : Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: maroonVendor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: maroonVendor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: maroonVendor)),
                ),
                if (analysis != null)
                  Chip(
                    label: Text(
                      analysis['priority'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: getPriorityColor(analysis['priority']),
                  ),
              ],
            ),
            Text('Current Stock: ${order['currentStock']}'),
            Text('Suggested Quantity: ${order['suggestedQuantity']}'),
            if (analysis != null) ...[
              Text('Priority: ${analysis['priority']}'),
              Text('Sales Velocity: ${analysis['salesVelocity'].toStringAsFixed(2)} units/week'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edit Quantity'),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Edit suggested quantity',
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () async {
                      final newQty = int.tryParse(qtyController.text) ?? order['suggestedQuantity'];
                      await SalesService.editDraftOrder(order['id'], newQty);
                      await _checkAndLoadDraftOrders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Draft order updated.'), backgroundColor: maroonVendor),
                      );
                    },
                  ),
                ),
                Tooltip(
                  message: 'Approve and create order',
                  child: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () async {
                      await SalesService.approveDraftOrder(order['id']);
                      await _checkAndLoadDraftOrders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order approved!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
                Tooltip(
                  message: 'Reject draft order',
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () async {
                      await SalesService.rejectDraftOrder(order['id']);
                      await _checkAndLoadDraftOrders();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Draft order rejected.'), backgroundColor: Colors.red),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 