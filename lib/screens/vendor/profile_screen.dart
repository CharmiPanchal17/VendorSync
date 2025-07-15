import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

// Rename color constants to avoid export conflicts
const maroonVendorProfile = Color(0xFF800000);
const lightCyanVendorProfile = Color(0xFFAFFFFF);

class VendorProfileScreen extends StatefulWidget {
  final String vendorEmail;
  
  const VendorProfileScreen({super.key, required this.vendorEmail});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  Map<String, dynamic>? vendorData;
  bool isLoading = true;
  String? errorMessage;
  int suppliersCount = 0;
  int totalOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchVendorData();
    _fetchSuppliersCount();
    _fetchTotalOrdersCount();
  }

  Future<void> _fetchVendorData() async {
    try {
      final vendorQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('email', isEqualTo: widget.vendorEmail)
          .limit(1)
          .get();

      if (vendorQuery.docs.isNotEmpty) {
        setState(() {
          vendorData = vendorQuery.docs.first.data();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Vendor not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load vendor data';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSuppliersCount() async {
    try {
      // Count suppliers linked to this vendor in vendor_suppliers collection
      final vendorSuppliersQuery = await FirebaseFirestore.instance
          .collection('vendor_suppliers')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .get();
      
      setState(() {
        suppliersCount = vendorSuppliersQuery.docs.length;
      });
    } catch (e) {
      // If there's an error fetching suppliers count, we'll just show 0
      setState(() {
        suppliersCount = 0;
      });
    }
  }

  Future<void> _fetchTotalOrdersCount() async {
    try {
      // Count all orders for this vendor
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .get();
      
      setState(() {
        totalOrdersCount = ordersQuery.docs.length;
      });
    } catch (e) {
      // If there's an error fetching orders count, we'll just show 0
      setState(() {
        totalOrdersCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vendor Profile'),
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
                  : [maroonVendorProfile, maroonVendorProfile.withOpacity(0.8)],
              ),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vendor Profile'),
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
                  : [maroonVendorProfile, maroonVendorProfile.withOpacity(0.8)],
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
                onPressed: _fetchVendorData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract vendor data with fallbacks
    final String vendorName = vendorData?['name'] ?? 'Unknown Vendor';
    final String email = vendorData?['email'] ?? widget.vendorEmail;
    final String phone = vendorData?['phone'] ?? 'Not provided';
    final String company = vendorData?['company'] ?? 'Not specified';
    final Timestamp? createdAt = vendorData?['createdAt'];
    final String createdDate = createdAt != null 
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Profile'),
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
                : [maroonVendorProfile, maroonVendorProfile.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : lightCyanVendorProfile,
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
                              : maroonVendorProfile.withOpacity(0.08),
                          child: Icon(
                            Icons.store, 
                            size: 48, 
                            color: isDark ? colorScheme.primary : maroonVendorProfile,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          vendorName,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('Total Orders', totalOrdersCount, isDark ? colorScheme.primary : maroonVendorProfile),
                            _buildStatCard('Suppliers', suppliersCount, isDark ? colorScheme.secondary : maroonVendorProfile),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditVendorProfileScreen(
                                  vendorEmail: widget.vendorEmail,
                                  vendorData: vendorData ?? {},
                                ),
                              ),
                            );
                            
                            // If the edit was successful, refresh the data
                            if (result == true) {
                              _fetchVendorData();
                              _fetchSuppliersCount();
                              _fetchTotalOrdersCount();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? colorScheme.primary : maroonVendorProfile,
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
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark 
                ? colorScheme.primary.withOpacity(0.2)
                : maroonVendorProfile.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: isDark ? colorScheme.primary : maroonVendorProfile, 
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
            label == 'Total Orders' ? Icons.shopping_cart : Icons.group,
            color: isDark ? colorScheme.primary : maroonVendorProfile,
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
              color: isDark ? colorScheme.primary : maroonVendorProfile,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 