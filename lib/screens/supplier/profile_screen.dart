import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

class SupplierProfileScreen extends StatefulWidget {
  final String supplierEmail;
  const SupplierProfileScreen({super.key, required this.supplierEmail});

  @override
  State<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  Map<String, dynamic>? supplierData;
  bool isLoading = true;
  String? errorMessage;
  int deliveredOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSupplierData();
    _fetchDeliveredOrdersCount();
  }

  Future<void> _fetchSupplierData() async {
    try {
      final supplierQuery = await FirebaseFirestore.instance
          .collection('suppliers')
          .where('email', isEqualTo: widget.supplierEmail)
          .limit(1)
          .get();
      if (supplierQuery.docs.isNotEmpty) {
        setState(() {
          supplierData = supplierQuery.docs.first.data();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Supplier not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load supplier data';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDeliveredOrdersCount() async {
    try {
      // Count orders where supplier email matches and status is 'Delivered'
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('supplierEmail', isEqualTo: widget.supplierEmail)
          .where('status', isEqualTo: 'Delivered')
          .get();
      
      setState(() {
        deliveredOrdersCount = ordersQuery.docs.length;
      });
    } catch (e) {
      // If there's an error fetching orders count, we'll just show 0
      setState(() {
        deliveredOrdersCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maroon = Color(0xFF800000);
    const lightCyan = Color(0xFFAFFFFF);
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Supplier Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                  : [maroon, maroon.withOpacity(0.8)],
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Supplier Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                  : [maroon, maroon.withOpacity(0.8)],
              ),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 18, 
                  color: isDark ? Colors.red.shade400 : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSupplierData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final String supplierName = supplierData?['name'] ?? 'Unknown Supplier';
    final String email = supplierData?['email'] ?? widget.supplierEmail;
    final String phone = supplierData?['phone'] ?? 'Not provided';
    final String company = supplierData?['company'] ?? 'Not specified';
    final Timestamp? createdAt = supplierData?['createdAt'];
    final String createdDate = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Profile'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                : [maroon, maroon.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                  color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: isDark 
                              ? colorScheme.primary.withOpacity(0.2)
                              : maroon.withOpacity(0.08),
                          child: Icon(
                            Icons.local_shipping, 
                            size: 48, 
                            color: isDark ? colorScheme.primary : maroon,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          supplierName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          color: isDark ? colorScheme.onSurface.withOpacity(0.2) : Colors.grey.shade300,
                        ),
                        _buildInfoRow(Icons.email, 'Email', email),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.phone, 'Phone', phone),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.calendar_today, 'Account Created', createdDate),
                        const SizedBox(height: 24),
                        _buildStatCard('Orders Fulfilled', deliveredOrdersCount, isDark ? colorScheme.primary : maroon),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditSupplierProfileScreen(
                                  supplierEmail: widget.supplierEmail,
                                  supplierData: supplierData ?? {},
                                ),
                              ),
                            );
                            
                            // If the edit was successful, refresh the data
                            if (result == true) {
                              _fetchSupplierData();
                              _fetchDeliveredOrdersCount();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? colorScheme.primary : maroon,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maroon = Color(0xFF800000);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark 
                ? colorScheme.primary.withOpacity(0.2)
                : maroon.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: isDark ? colorScheme.primary : maroon, 
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? colorScheme.onSurface.withOpacity(0.6) : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maroon = Color(0xFF800000);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? color.withOpacity(0.2)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in, 
            color: isDark ? colorScheme.primary : maroon, 
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? colorScheme.primary : maroon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 