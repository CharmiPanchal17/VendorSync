import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

const maroonQuick = Color(0xFF800000);
const lightCyanQuick = Color(0xFFAFFFFF);

class QuickOrderScreen extends StatefulWidget {
  final String vendorEmail;
  final String productName;
  final int suggestedQuantity;
  final String? supplierEmail;
  final String? supplierName;
  
  const QuickOrderScreen({
    super.key,
    required this.vendorEmail,
    required this.productName,
    required this.suggestedQuantity,
    this.supplierEmail,
    this.supplierName,
  });

  @override
  State<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends State<QuickOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  String? _selectedSupplierEmail;
  
  DateTime _preferredDeliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  List<Map<String, dynamic>> availableSuppliers = [];

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.suggestedQuantity.toString();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliersSnapshot = await FirebaseFirestore.instance
          .collection('vendor_suppliers')
          .where('vendorEmail', isEqualTo: widget.vendorEmail)
          .get();

      final suppliers = suppliersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['supplierName'] ?? '',
          'email': data['supplierEmail'] ?? '',
          'phone': data['supplierPhone'] ?? '',
          'address': data['supplierAddress'] ?? '',
        };
      }).toList();

      setState(() {
        availableSuppliers = suppliers;
      });

      // Auto-select the primary supplier if available
      if (widget.supplierEmail != null) {
        final primarySupplier = suppliers.firstWhere(
          (supplier) => supplier['email'] == widget.supplierEmail,
          orElse: () => suppliers.isNotEmpty ? suppliers.first : {},
        );
        
        if (primarySupplier.isNotEmpty) {
          setState(() {
            _selectedSupplierId = primarySupplier['id'];
            _selectedSupplierName = primarySupplier['name'];
            _selectedSupplierEmail = primarySupplier['email'];
          });
        }
      }
    } catch (e) {
      print('Error loading suppliers: $e');
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierEmail == null) {
      setState(() {
        _errorMessage = 'Please select a supplier';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderData = {
        'productName': widget.productName,
        'quantity': int.parse(_quantityController.text),
        'supplierName': _selectedSupplierName,
        'supplierEmail': _selectedSupplierEmail,
        'vendorEmail': widget.vendorEmail,
        'status': 'Pending',
        'preferredDeliveryDate': Timestamp.fromDate(_preferredDeliveryDate),
        'notes': _notesController.text.trim(),
        'isAutoOrder': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final orderRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);

      // Create notification for supplier
      await NotificationService.notifySupplierOfNewOrder(
        supplierEmail: _selectedSupplierEmail!,
        vendorEmail: widget.vendorEmail,
        orderId: orderRef.id,
        productName: widget.productName,
        quantity: int.parse(_quantityController.text),
      );

      setState(() {
        _successMessage = 'Order placed successfully!';
        _isLoading = false;
      });

      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error placing order: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Order'),
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
                      : [maroonQuick, maroonQuick.withOpacity(0.8)],
            ),
          ),
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF2D2D2D) : lightCyanQuick,
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
                                                      backgroundColor: maroonQuick.withOpacity(0.2),
                      child: Icon(Icons.shopping_cart, color: maroonQuick),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quick Order',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Place order for ${widget.productName}',
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
                  
                  // Product Information
                  _buildSectionHeader('Product Information', Icons.inventory, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow('Product', widget.productName, isDark),
                          const SizedBox(height: 12),
                          _buildInfoRow('Suggested Quantity', '${widget.suggestedQuantity}', isDark),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Order Details
                  _buildSectionHeader('Order Details', Icons.edit, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _quantityController,
                            decoration: _buildInputDecoration(
                              'Order Quantity',
                              Icons.format_list_numbered,
                              isDark,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter quantity';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null || quantity <= 0) {
                                return 'Please enter a valid quantity';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: _buildInputDecoration(
                              'Notes (Optional)',
                              Icons.note,
                              isDark,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Supplier Selection
                  _buildSectionHeader('Supplier Selection', Icons.person, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (availableSuppliers.isEmpty)
                            _buildEmptySuppliersState(isDark)
                          else
                            ...availableSuppliers.map((supplier) => _buildSupplierOption(
                              supplier,
                              isDark,
                            )).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Delivery Date
                  _buildSectionHeader('Delivery Date', Icons.calendar_today, isDark),
                  const SizedBox(height: 16),
                  
                  Card(
                    color: isDark ? Colors.white10 : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () => _selectDeliveryDate(isDark),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: maroonQuick,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preferred Delivery Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white60 : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(_preferredDeliveryDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Error/Success Messages
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  if (_successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                                          style: ElevatedButton.styleFrom(
                      backgroundColor: maroonQuick,
                      foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
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
        Icon(
          icon,
          color: maroonQuick,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
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
      prefixIcon: Icon(icon, color: maroonQuick),
      border: const OutlineInputBorder(),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.grey[600],
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: maroonQuick),
      ),
    );
  }

  Widget _buildSupplierOption(Map<String, dynamic> supplier, bool isDark) {
    final isSelected = _selectedSupplierId == supplier['id'];
    
    return RadioListTile<String>(
      value: supplier['id'],
      groupValue: _selectedSupplierId,
      onChanged: (value) {
        setState(() {
          _selectedSupplierId = value;
          _selectedSupplierName = supplier['name'];
          _selectedSupplierEmail = supplier['email'];
        });
      },
      title: Text(
        supplier['name'],
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        supplier['email'],
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
        ),
      ),
      activeColor: maroonQuick,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEmptySuppliersState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.person_off,
            size: 48,
            color: isDark ? Colors.white24 : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No suppliers available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add suppliers to your network to place orders.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDeliveryDate(bool isDark) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _preferredDeliveryDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: maroonQuick,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _preferredDeliveryDate = selectedDate;
      });
    }
  }
} 