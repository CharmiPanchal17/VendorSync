import '../models/order.dart';

final List<Order> mockOrders = [
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
final List<StockItem> mockStockItems = []; 