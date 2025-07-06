import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

const maroon = Color(0xFF800000);
const lightCyan = Color(0xFFAFFFFF);

class CreateOrderScreen extends StatefulWidget {
  final String vendorEmail;
  
  const CreateOrderScreen({super.key, required this.vendorEmail});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _thresholdController = TextEditingController();
  
  // Supplier selection
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  String? _selectedSupplierEmail;
  
  DateTime _preferredDeliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Auto-order settings
  bool _enableAutoOrder = true;
  int _autoOrderQuantity = 0;

  @override
  void initState() {
    super.initState();
    // Set default threshold to 30% of initial quantity
    _thresholdController.text = '30';
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
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
        color: isDark ? const Color(0xFF2D2D2D) : lightCyan,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: maroon.withOpacity(0.2),
                                child: Icon(Icons.add_shopping_cart, color: maroon),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create New Order',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Set up initial order and auto-ordering',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Product Information Section
                  _buildSectionHeader('Product Information', Icons.inventory, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _productNameController,
                            decoration: _buildInputDecoration(
                              'Product Name',
                              Icons.inventory,
                              isDark,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _quantityController,
                            decoration: _buildInputDecoration(
                              'Initial Quantity',
                              Icons.format_list_numbered,
                              isDark,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter initial quantity';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null || quantity <= 0) {
                                return 'Please enter a valid quantity';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateAutoOrderQuantity();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Supplier Information Section
                  _buildSectionHeader('Supplier Information', Icons.person, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('vendor_suppliers')
                                .where('vendorEmail', isEqualTo: widget.vendorEmail)
                                .snapshots(),
                            builder: (context, vendorSuppliersSnapshot) {
                              if (vendorSuppliersSnapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  child: const Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text('Loading suppliers...'),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              if (vendorSuppliersSnapshot.hasError) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Error loading suppliers',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error: ${vendorSuppliersSnapshot.error}',
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              final vendorSupplierDocs = vendorSuppliersSnapshot.data?.docs ?? [];
                              
                              if (vendorSupplierDocs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'No suppliers found',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Please add suppliers from the "My Suppliers" page first.',
                                        style: TextStyle(
                                          color: Colors.orange.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed('/vendor-suppliers', arguments: widget.vendorEmail);
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Suppliers'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              final supplierIds = vendorSupplierDocs.map((doc) => doc['supplierId'] as String).toList();
                              
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('suppliers')
                                    .where(FieldPath.documentId, whereIn: supplierIds)
                                    .snapshots(),
                                builder: (context, suppliersSnapshot) {
                                  if (suppliersSnapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      child: const Center(
                                        child: Column(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 8),
                                            Text('Loading supplier details...'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  if (suppliersSnapshot.hasError) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.red, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Error loading supplier details',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Error: ${suppliersSnapshot.error}',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  final supplierDocs = suppliersSnapshot.data?.docs ?? [];
                                  
                                  if (supplierDocs.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.red, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'No supplier data found',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Found ${supplierIds.length} supplier IDs but no supplier data.',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Debug info (remove in production)
                                      if (supplierDocs.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Found ${supplierDocs.length} suppliers',
                                            style: TextStyle(fontSize: 12, color: Colors.blue),
                                          ),
                                        ),
                                      
                                      // Supplier Selection Dropdown
                                      Container(
                                        width: double.infinity,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText: 'Select Supplier',
                                            labelStyle: TextStyle(
                                              color: isDark ? Colors.white70 : Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: maroon.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.person, color: maroon, size: 20),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: maroon, width: 2),
                                            ),
                                            filled: true,
                                            fillColor: isDark ? Colors.white10 : Colors.white,
                                          ),
                                          value: _selectedSupplierId,

                                          items: [
                                            // Add a placeholder item
                                            DropdownMenuItem<String>(
                                              value: null,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      _selectedSupplierId == null 
                                                          ? 'Choose a supplier...'
                                                          : 'Change supplier...',
                                                      style: TextStyle(
                                                        color: isDark ? Colors.white70 : Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Add actual supplier items
                                            ...supplierDocs.map((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              final supplierName = data['name'] ?? 'Unknown Supplier';
                                              final supplierEmail = data['email'] ?? 'No email';
                                              final supplierPhone = data['phone'] ?? '';
                                              
                                              return DropdownMenuItem<String>(
                                                value: doc.id,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Supplier Avatar
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: maroon.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            supplierName.isNotEmpty ? supplierName[0].toUpperCase() : 'S',
                                                            style: TextStyle(
                                                              color: maroon,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // Supplier Details
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              supplierName,
                                                              style: TextStyle(
                                                                color: isDark ? Colors.white : Colors.black87,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 14,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.email_outlined,
                                                                  size: 12,
                                                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    supplierEmail,
                                                                    style: TextStyle(
                                                                      color: isDark ? Colors.white60 : Colors.grey[600],
                                                                      fontSize: 12,
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            if (supplierPhone.isNotEmpty) ...[
                                                              const SizedBox(height: 2),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons.phone_outlined,
                                                                    size: 12,
                                                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Expanded(
                                                                    child: Text(
                                                                      supplierPhone,
                                                                      style: TextStyle(
                                                                        color: isDark ? Colors.white60 : Colors.grey[600],
                                                                        fontSize: 12,
                                                                      ),
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      // Selection indicator
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: maroon.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Icon(
                                                          Icons.check_circle_outline,
                                                          color: maroon,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                          onChanged: (value) {
                                            print('Dropdown changed to: $value'); // Debug print
                                            if (value != null) {
                                              final selectedDoc = supplierDocs.firstWhere((doc) => doc.id == value);
                                              final data = selectedDoc.data() as Map<String, dynamic>;
                                              setState(() {
                                                _selectedSupplierId = value;
                                                _selectedSupplierName = data['name'] ?? 'Unknown Supplier';
                                                _selectedSupplierEmail = data['email'] ?? '';
                                              });
                                              print('Selected supplier: $_selectedSupplierName ($_selectedSupplierEmail)'); // Debug print
                                            } else {
                                              setState(() {
                                                _selectedSupplierId = null;
                                                _selectedSupplierName = null;
                                                _selectedSupplierEmail = null;
                                              });
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select a supplier';
                                            }
                                            return null;
                                          },
                                          menuMaxHeight: 300,
                                          isExpanded: true,
                                          dropdownColor: isDark ? const Color(0xFF3D3D3D) : Colors.white,
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: maroon,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      
                                      if (_selectedSupplierName != null && _selectedSupplierEmail != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: maroon.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: maroon.withOpacity(0.3)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: maroon, size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Selected Supplier',
                                                    style: TextStyle(
                                                      color: maroon,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Name: $_selectedSupplierName',
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Email: $_selectedSupplierEmail',
                                                style: TextStyle(
                                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Delivery Information Section
                  _buildSectionHeader('Delivery Information', Icons.local_shipping, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () => _selectDeliveryDate(context, isDark),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: maroon.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.calendar_today, color: maroon),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preferred Delivery Date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    DateFormat.yMMMd().format(_preferredDeliveryDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.white70 : Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Auto-Order Settings Section
                  _buildSectionHeader('Auto-Order Settings', Icons.settings, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Enable Auto-Ordering',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              'Automatically place orders when stock is low',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                            value: _enableAutoOrder,
                            onChanged: (value) {
                              setState(() {
                                _enableAutoOrder = value;
                              });
                            },
                            activeColor: maroon,
                          ),
                          if (_enableAutoOrder) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _thresholdController,
                              decoration: _buildInputDecoration(
                                'Low Stock Threshold (%)',
                                Icons.warning,
                                isDark,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (!_enableAutoOrder) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter threshold percentage';
                                }
                                final threshold = int.tryParse(value);
                                if (threshold == null || threshold <= 0 || threshold >= 100) {
                                  return 'Please enter a valid percentage (1-99)';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _updateAutoOrderQuantity();
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: maroon.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: maroon.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: maroon, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Auto-order will be placed when stock reaches ${_thresholdController.text}% of initial quantity (${_autoOrderQuantity} units)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: maroon,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Error/Success Messages
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  // Create Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 100), // Extra space for floating action button
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: maroon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: maroon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: maroon, size: 20),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: maroon, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: isDark ? Colors.white10 : Colors.white,
    );
  }

  Future<void> _selectDeliveryDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDeliveryDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? Colors.white : maroon,
              onPrimary: isDark ? Colors.black : Colors.white,
              surface: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _preferredDeliveryDate = picked;
      });
    }
  }

  void _updateAutoOrderQuantity() {
    final quantity = int.tryParse(_quantityController.text);
    final threshold = int.tryParse(_thresholdController.text);
    
    if (quantity != null && threshold != null && threshold > 0 && threshold < 100) {
      setState(() {
        _autoOrderQuantity = (quantity * threshold / 100).round();
      });
    }
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final quantity = int.parse(_quantityController.text);
      final threshold = _enableAutoOrder ? int.parse(_thresholdController.text) : 0;
      
      // Create the order document
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'productName': _productNameController.text.trim(),
        'quantity': quantity,
        'supplierName': _selectedSupplierName,
        'supplierEmail': _selectedSupplierEmail,
        'vendorEmail': widget.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': _preferredDeliveryDate,
        'autoOrderEnabled': _enableAutoOrder,
        'autoOrderThreshold': threshold,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create product inventory record for auto-ordering
      await FirebaseFirestore.instance.collection('product_inventory').add({
        'productName': _productNameController.text.trim(),
        'supplierName': _selectedSupplierName,
        'supplierEmail': _selectedSupplierEmail,
        'vendorEmail': widget.vendorEmail,
        'initialQuantity': quantity,
        'currentStock': quantity,
        'lowStockThreshold': threshold,
        'autoOrderEnabled': _enableAutoOrder,
        'autoOrderQuantity': _autoOrderQuantity,
        'lastOrderId': orderRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to supplier
      await NotificationService.notifySupplierOfNewOrder(
        vendorEmail: widget.vendorEmail,
        supplierEmail: _selectedSupplierEmail!,
        orderId: orderRef.id,
        productName: _productNameController.text.trim(),
        quantity: quantity,
      );

      setState(() {
        _isLoading = false;
        _successMessage = 'Order created successfully! Supplier has been notified.';
      });

      // Clear form after successful creation
      _formKey.currentState!.reset();
      _productNameController.clear();
      _quantityController.clear();
      _thresholdController.text = '30';
      _preferredDeliveryDate = DateTime.now().add(const Duration(days: 7));
      _enableAutoOrder = true;
      _autoOrderQuantity = 0;
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _selectedSupplierEmail = null;

      // Show success dialog
      if (context.mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(context, orderRef.id, isDark),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create order. Please try again.';
      });
    }
  }

  Widget _buildSuccessDialog(BuildContext context, String orderId, bool isDark) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Success Animation Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [maroon, maroon.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: maroon.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            
            // Success Title
            Text(
              'Order Created Successfully!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Success Message
            Text(
              'Your order has been placed and the supplier has been notified.',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Order Details Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: maroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: maroon.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Product Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: maroon.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory, color: maroon, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _productNameController.text.trim(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                                     const SizedBox(height: 10),
                   
                   // Order ID
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: maroon.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt, color: maroon, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              orderId,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: maroon,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                                     ),
                   const SizedBox(height: 10),
                   
                   // Supplier Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: maroon.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: maroon, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supplier',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _selectedSupplierName ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                                     ),
                   
                   // Auto-order info if enabled
                   if (_enableAutoOrder) ...[
                     const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Auto-ordering enabled',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/vendor-dashboard', arguments: widget.vendorEmail);
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Go to Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: maroon,
                      side: BorderSide(color: maroon),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
} 