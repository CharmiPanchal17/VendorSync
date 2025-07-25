import '../models/order.dart';

final List<Order> mockOrders = [
  Order(
    id: '1',
    productName: 'Widgets',
    quantity: 100,
    supplierName: 'Supplier A',
    supplierEmail: 'supplierA@example.com',
    status: 'Pending',
    preferredDeliveryDate: DateTime.now().add(Duration(days: 3)),
    unitPrice: 15.50,
    notes: 'Standard delivery',
  ),
  Order(
    id: '2',
    productName: 'Gadgets',
    quantity: 50,
    supplierName: 'Supplier B',
    supplierEmail: 'supplierB@example.com',
    status: 'Confirmed',
    preferredDeliveryDate: DateTime.now().add(Duration(days: 5)),
    unitPrice: 25.00,
    notes: 'Express delivery requested',
  ),
  Order(
    id: '3',
    productName: 'Thingamajigs',
    quantity: 200,
    supplierName: 'Supplier C',
    supplierEmail: 'supplierC@example.com',
    status: 'Delivered',
    preferredDeliveryDate: DateTime.now().subtract(Duration(days: 2)),
    actualDeliveryDate: DateTime.now().subtract(Duration(days: 1)),
    unitPrice: 12.75,
    notes: 'Delivered on time',
  ),
];

// Mock delivery records
final List<DeliveryRecord> mockDeliveryRecords = [
  DeliveryRecord(
    id: 'del_1',
    orderId: '3',
    productName: 'Thingamajigs',
    quantity: 200,
    supplierName: 'Supplier C',
    supplierEmail: 'supplierC@example.com',
    deliveryDate: DateTime.now().subtract(Duration(days: 1)),
    unitPrice: null, // Removed price
    notes: 'First delivery - excellent quality',
    status: 'Completed',
    vendorEmail: 'demo@vendor.com',
  ),
  DeliveryRecord(
    id: 'del_2',
    orderId: '4',
    productName: 'Widgets',
    quantity: 150,
    supplierName: 'Supplier A',
    supplierEmail: 'supplierA@example.com',
    deliveryDate: DateTime.now().subtract(Duration(days: 5)),
    unitPrice: null, // Removed price
    notes: 'Second delivery - good condition',
    status: 'Completed',
    vendorEmail: 'demo@vendor.com',
  ),
  DeliveryRecord(
    id: 'del_3',
    orderId: '5',
    productName: 'Gadgets',
    quantity: 75,
    supplierName: 'Supplier B',
    supplierEmail: 'supplierB@example.com',
    deliveryDate: DateTime.now().subtract(Duration(days: 8)),
    unitPrice: null, // Removed price
    notes: 'First delivery - premium quality',
    status: 'Completed',
    vendorEmail: 'demo@vendor.com',
  ),
  DeliveryRecord(
    id: 'del_4',
    orderId: '6',
    productName: 'Widgets',
    quantity: 100,
    supplierName: 'Supplier A',
    supplierEmail: 'supplierA@example.com',
    deliveryDate: DateTime.now().subtract(Duration(days: 12)),
    unitPrice: null, // Removed price
    notes: 'First delivery - standard quality',
    status: 'Completed',
    vendorEmail: 'demo@vendor.com',
  ),
];

// Mock stock items with delivery history
final List<StockItem> mockStockItems = [
  StockItem(
    id: 'stock_1',
    productName: 'Widgets',
    currentStock: 25,
    minimumStock: 20,
    maximumStock: 250,
    deliveryHistory: mockDeliveryRecords.where((record) => record.productName == 'Widgets').toList(),
    primarySupplier: 'Supplier A',
    primarySupplierEmail: 'supplierA@example.com',
    firstDeliveryDate: DateTime.now().subtract(Duration(days: 12)),
    lastDeliveryDate: DateTime.now().subtract(Duration(days: 5)),
    autoOrderEnabled: true,
    averageUnitPrice: null, // Removed price
    vendorEmail: 'demo@vendor.com',
  ),
]; 