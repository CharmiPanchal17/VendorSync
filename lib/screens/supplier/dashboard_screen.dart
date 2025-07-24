import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart' as order_model;
import '../../services/session_service.dart';

class SupplierDashboardScreen extends StatefulWidget {
  final String supplierEmail;
  
  const SupplierDashboardScreen({super.key, required this.supplierEmail});

  @override
  State<SupplierDashboardScreen> createState() => _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  String selectedStatus = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _updateSessionActivity();
  }

  Future<void> _updateSessionActivity() async {
    // Update session activity to extend the session
    await SessionService.updateLastActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        color: Colors.white,
        child: SafeArea(
            child: Column(
              children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                      children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text(
                            'Supplier Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Welcome back, ${widget.supplierEmail}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        Row(
                  children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.inventory,
                                title: 'Total Orders',
                                value: _buildTotalOrdersCount(),
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.pending,
                                title: 'Pending',
                                value: _buildPendingOrdersCount(),
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.check_circle,
                                title: 'Confirmed',
                                value: _buildConfirmedOrdersCount(),
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.local_shipping,
                                title: 'Delivered',
                                value: _buildDeliveredOrdersCount(),
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
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
                        
                        // Orders List (appears directly below filter)
                        const SizedBox(height: 16),
                        
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('supplierEmail', isEqualTo: widget.supplierEmail)
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
                                      'Orders from vendors will appear here',
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
                                      'Try changing the filter',
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
                                          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
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
                                          'Vendor: ${data['vendorEmail'] ?? 'Unknown Vendor'}',
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
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
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
                          ],
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
                                      Navigator.of(context).pushNamed('/supplier-order-details', arguments: orderData);
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required Widget value,
    required Color color,
  }) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          value,
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF43E97B),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF43E97B), Color(0xFF38F9D7)], // Green gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Supplier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.supplierEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildMenuItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => Navigator.of(context).pop(),
              isSelected: true,
            ),
            _buildMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/supplier-notifications');
              },
            ),
            _buildMenuItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/supplier-profile');
              },
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _showLogoutDialog(),
              isLogout: true,
            ),
          ],
        ),
      ),
    );
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
                : (isSelected ? Colors.white : Colors.white.withOpacity(0.9)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF43E97B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              // Clear the session data
              await SessionService.clearSession();
              
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/welcome');
            },
            child: const Text('Logout'),
          ),
        ],
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

  Widget _buildTotalOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('supplierEmail', isEqualTo: widget.supplierEmail)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        );
      },
    );
  }

  Widget _buildPendingOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('supplierEmail', isEqualTo: widget.supplierEmail)
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        );
      },
    );
  }

  Widget _buildConfirmedOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('supplierEmail', isEqualTo: widget.supplierEmail)
          .where('status', isEqualTo: 'Confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        );
      },
    );
  }

  Widget _buildDeliveredOrdersCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('supplierEmail', isEqualTo: widget.supplierEmail)
          .where('status', isEqualTo: 'Delivered')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        );
      },
    );
  }
} 