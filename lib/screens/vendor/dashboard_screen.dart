import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../mock_data/mock_orders.dart';
import '../../models/order.dart' as order_model;
import 'suppliers_list_screen.dart';
import 'create_order_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchVendorName();
  }

  Future<void> _fetchVendorName() async {
    final vendorQuery = await FirebaseFirestore.instance
        .collection('vendors')
        .where('email', isEqualTo: widget.vendorEmail)
        .limit(1)
        .get();
    if (vendorQuery.docs.isNotEmpty) {
      setState(() {
        vendorName = vendorQuery.docs.first['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2196F3), // Blue
                Color(0xFF43E97B), // Green
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
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
                      child: Icon(Icons.store, size: 40, color: Colors.white),
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
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.add_shopping_cart,
                      title: 'Create Order',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => VendorCreateOrderScreen(vendorEmail: widget.vendorEmail),
                        ));
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/vendor-notifications');
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/vendor-profile');
                      },
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
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout? This will remove your vendor details from the system.'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // Find and delete the vendor document by email
                          final vendorQuery = await FirebaseFirestore.instance
                              .collection('vendors')
                              .where('email', isEqualTo: widget.vendorEmail)
                              .limit(1)
                              .get();
                          if (vendorQuery.docs.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('vendors')
                                .doc(vendorQuery.docs.first.id)
                                .delete();
                          }
                          // Navigate to login page
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false, arguments: 'vendor');
                          }
                        }
                      },
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2196F3), // Blue
                Color(0xFF43E97B), // Green
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3), // Blue
              Color(0xFF43E97B), // Green
            ],
          ),
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
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
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
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage your orders and suppliers efficiently',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
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
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
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
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Calendar & Filters',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TableCalendar(
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
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                              ),
                              weekendTextStyle: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Summary Cards
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
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
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.analytics, color: Colors.blue.shade700, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
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
                                  color: Colors.green,
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
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Filter
                  Text(
                    'Filter Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
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
                        _buildStatusButton('Delivered', Colors.green),
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
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.inventory, color: Colors.white, size: 24),
                              ),
                              title: Text(
                                data['productName'] ?? 'Unknown Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supplier: ${data['supplierName'] ?? 'Unknown Supplier'}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Quantity: ${data['quantity'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (data['preferredDeliveryDate'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Delivery: ${DateFormat.yMMMd().format((data['preferredDeliveryDate'] as Timestamp).toDate())}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
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
                                        onPressed: () => _approveOrder(orderId),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VendorCreateOrderScreen(vendorEmail: widget.vendorEmail),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create New Order',
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
        return Colors.green.shade100;
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
        return Colors.green;
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
        return Colors.green;
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: isLogout 
              ? Colors.red.shade300
              : (isSelected ? Colors.white : Colors.white.withOpacity(0.8)),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout 
                ? Colors.red.shade300
                : (isSelected ? Colors.white : Colors.white.withOpacity(0.8)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
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

  Future<void> _approveOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'Delivered',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order approved successfully!'),
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
            content: const Text('Failed to approve order. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
} 