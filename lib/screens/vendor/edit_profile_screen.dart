import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Add color constants at the top-level for use throughout the file
const maroonVendorEdit = Color(0xFF800000);
const lightCyanVendorEdit = Color(0xFFAFFFFF);

class EditVendorProfileScreen extends StatefulWidget {
  final String vendorEmail;
  final Map<String, dynamic> vendorData;

  const EditVendorProfileScreen({
    super.key,
    required this.vendorEmail,
    required this.vendorData,
  });

  @override
  State<EditVendorProfileScreen> createState() => _EditVendorProfileScreenState();
}

class _EditVendorProfileScreenState extends State<EditVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendorData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.vendorData['phone'] ?? '');
    _companyController = TextEditingController(text: widget.vendorData['company'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Find the vendor document
      final vendorQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('email', isEqualTo: widget.vendorEmail)
          .limit(1)
          .get();

      if (vendorQuery.docs.isNotEmpty) {
        // Update the vendor document
        await vendorQuery.docs.first.reference.update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'company': _companyController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isLoading = false);
        
        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: maroonVendorEdit,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Vendor not found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                : [maroonVendorEdit, maroonVendorEdit.withOpacity(0.8)],
            ),
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : lightCyanVendorEdit,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  color: isDark ? colorScheme.surface : Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: isDark ? colorScheme.primary.withOpacity(0.2) : maroonVendorEdit.withOpacity(0.08),
                            child: Icon(Icons.store, size: 48, color: isDark ? colorScheme.primary : maroonVendorEdit),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? colorScheme.onSurface : const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field (Read-only)
                          TextFormField(
                            initialValue: widget.vendorEmail,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            enabled: false,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Company Field
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company Name',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your company name';
                              }
                              return null;
                            },
                          ),
                          
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? Colors.red.shade400 : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red.shade600),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Save Button
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveChanges,
                            icon: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: maroonVendorEdit,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Cancel Button
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade700,
                              side: BorderSide(
                                color: isDark ? colorScheme.onSurface.withOpacity(0.3) : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      ),
    );
  }
} 