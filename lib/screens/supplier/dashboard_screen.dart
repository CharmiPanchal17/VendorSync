import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart' as order_model;
import '../../services/notification_service.dart';
import 'settings_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Add color constant at the top-level for use throughout the file
const _maroonSupplier = Color(0xFF800000);

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Solid light cyan background (like welcome page)
          if (!isDark)
            Container(
              color: const Color(0xFFAFFFFF),
            ),
          if (isDark)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3D3D3D), Color(0xFF2D2D2D)],
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                // Header
                ClipPath(
                  clipper: ConvexHeaderClipper(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                          ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                          : [_maroonSupplier, _maroonSupplier.withOpacity(0.8)],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supplier Dashboard',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Welcome back, ${widget.supplierEmail}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Notification Bell with Badge
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/supplier-notifications', arguments: widget.supplierEmail);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            // Notification Badge
                            Positioned(
                              right: 0,
                              top: 0,
                              child: StreamBuilder<int>(
                                stream: NotificationService.getUnreadNotificationCount(widget.supplierEmail),
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
                      ],
                    ),
                  ),
                ),
                // Main Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D2D) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
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
                                  color: _maroonSupplier, // Changed from Colors.green to maroon
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
                                _buildStatusButton('Delivered', _maroonSupplier), // Changed from Colors.green to maroon
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
                                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Loading orders...',
                                        style: TextStyle(
                                          color: isDark ? colorScheme.onSurface : Colors.black,
                                        ),
                                      ),
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
                                          style: TextStyle(
                                            color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                                          ),
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
                                          gradient: LinearGradient(
                                            colors: isDark 
                                              ? [colorScheme.primary, colorScheme.secondary]
                                              : [const Color(0xFF2196F3), const Color(0xFF43E97B)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.inventory_outlined, color: Colors.white, size: 32),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Orders Yet',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Orders from vendors will appear here',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
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
                                      Icon(
                                        Icons.filter_list, 
                                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, 
                                        size: 32
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No $selectedStatus orders',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? colorScheme.onSurface : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try changing the filter',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade500,
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
                                            colors: isDark 
                                              ? [colorScheme.primary, colorScheme.secondary]
                                              : [_maroonSupplier, _maroonSupplier.withOpacity(0.8)],
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
                                            'Vendor: ${data['vendorEmail'] ?? 'Unknown Vendor'}',
                                            style: TextStyle(
                                              color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Quantity: ${data['quantity'] ?? 'N/A'}',
                                            style: TextStyle(
                                              color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (data['preferredDeliveryDate'] != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Delivery: ${DateFormat.yMMMd().format((data['preferredDeliveryDate'] as Timestamp).toDate())}',
                                              style: TextStyle(
                                                color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
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
                                          supplierEmail: data['supplierEmail'] ?? 'unknown@example.com',
                                          quantity: data['quantity'] ?? 0,
                                          status: data['status'] ?? 'Pending',
                                          preferredDeliveryDate: data['preferredDeliveryDate'] != null 
                                              ? (data['preferredDeliveryDate'] as Timestamp).toDate()
                                              : DateTime.now(),
                                        );
                                        Navigator.of(context).pushNamed('/supplier-order-details', arguments: {
                                          'order': orderData,
                                          'supplierEmail': widget.supplierEmail,
                                        });
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
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required Widget value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
          backgroundColor: isSelected ? Colors.transparent : (isDark ? const Color(0xFF3D3D3D) : Colors.white),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const lightCyan = Color(0xFFAFFFFF);
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3D3D3D) : lightCyan,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3D3D3D) : _maroonSupplier,
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
                    child: Icon(Icons.local_shipping, size: 40, color: isDark ? Colors.white : _maroonSupplier),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supplier',
                    style: TextStyle(
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
                    widget.supplierEmail,
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
                    onTap: () => Navigator.of(context).pop(),
                    isSelected: true,
                    textColor: isDark ? Colors.white : _maroonSupplier,
                    iconColor: isDark ? Colors.white : _maroonSupplier,
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/supplier-notifications', arguments: widget.supplierEmail);
                    },
                    textColor: isDark ? Colors.white : _maroonSupplier,
                    iconColor: isDark ? Colors.white : _maroonSupplier,
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/supplier-profile', arguments: widget.supplierEmail);
                    },
                    textColor: isDark ? Colors.white : _maroonSupplier,
                    iconColor: isDark ? Colors.white : _maroonSupplier,
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SupplierSettingsScreen(supplierEmail: widget.supplierEmail),
                        ),
                      );
                    },
                    textColor: isDark ? Colors.white : _maroonSupplier,
                    iconColor: isDark ? Colors.white : _maroonSupplier,
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
                    textColor: _maroonSupplier,
                    iconColor: _maroonSupplier,
                  ),
                ],
              ),
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
    Color? textColor,
    Color? iconColor,
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
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLogoutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                    : [const Color(0xFF2196F3), const Color(0xFF43E97B)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? colorScheme.primary : Colors.blue,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _maroonSupplier,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              // Delete supplier document and navigate to login
              try {
                final query = await FirebaseFirestore.instance
                    .collection('suppliers')
                    .where('email', isEqualTo: widget.supplierEmail)
                    .limit(1)
                    .get();
                
                if (query.docs.isNotEmpty) {
                  await query.docs.first.reference.delete();
                }
              } catch (e) {
                // Handle error silently
              }
              
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
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
        return _maroonSupplier.withOpacity(0.08); // Changed from Colors.green.shade100 to maroon
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
        return _maroonSupplier; // Changed from Colors.green to maroon
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
        return _maroonSupplier; // Changed from Colors.green to maroon
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

class ConvexHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final curveHeight = 40.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - curveHeight);
    path.quadraticBezierTo(0, size.height, curveHeight, size.height);
    path.lineTo(size.width - curveHeight, size.height);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - curveHeight);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 