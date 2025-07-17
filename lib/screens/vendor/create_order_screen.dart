import 'package:flutter/material.dart';
import '../../mock_data/mock_order_data.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? selectedCategory;
  String? selectedSupplier;
  String? selectedItem;
  String? quantity;

  List<String> get suppliers {
    if (selectedCategory == null) return [];
    return categoriesData
        .firstWhere((cat) => cat['name'] == selectedCategory)['suppliers']
        .cast<String>();
  }

  List<String> get items {
    if (selectedCategory == null) return [];
    return categoriesData
        .firstWhere((cat) => cat['name'] == selectedCategory)['items']
        .cast<String>();
  }

  final _formKey = GlobalKey<FormState>();

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Order Summary'),
          content: Text(
            'Category: $selectedCategory\nSupplier: $selectedSupplier\nItem: $selectedItem\nQuantity: $quantity',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Order')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category'),
                value: selectedCategory,
                items: categoriesData
                    .map<DropdownMenuItem<String>>(
                        (cat) => DropdownMenuItem(
                              value: cat['name'],
                              child: Text(cat['name']),
                            ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val;
                    selectedSupplier = null;
                    selectedItem = null;
                  });
                },
                validator: (val) => val == null ? 'Please select a category' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Supplier'),
                value: selectedSupplier,
                items: suppliers
                    .map((sup) => DropdownMenuItem(
                          value: sup,
                          child: Text(sup),
                        ))
                    .toList(),
                onChanged: selectedCategory != null ? (val) {
                  setState(() {
                    selectedSupplier = val;
                  });
                } : null,
                validator: (val) => val == null ? 'Please select a supplier' : null,
                disabledHint: Text('Select a category first'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Item'),
                value: selectedItem,
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: selectedCategory != null ? (val) {
                  setState(() {
                    selectedItem = val;
                  });
                } : null,
                validator: (val) => val == null ? 'Please select an item' : null,
                disabledHint: Text('Select a category first'),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (val) => quantity = val,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter quantity';
                  final num? q = num.tryParse(val);
                  if (q == null || q <= 0) return 'Enter a valid quantity';
                  return null;
                },
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  child: Text('Submit Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 