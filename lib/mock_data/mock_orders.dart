import '../models/order.dart';

final List<Order> mockOrders = [
  Order(
    id: '1',
    productName: 'Widgets',
    quantity: 100,
    supplierName: 'Supplier A',
    status: 'Pending',
    preferredDeliveryDate: DateTime.now().add(Duration(days: 3)),
  ),
  Order(
    id: '2',
    productName: 'Gadgets',
    quantity: 50,
    supplierName: 'Supplier B',
    status: 'Confirmed',
    preferredDeliveryDate: DateTime.now().add(Duration(days: 5)),
  ),
  Order(
    id: '3',
    productName: 'Thingamajigs',
    quantity: 200,
    supplierName: 'Supplier C',
    status: 'Delivered',
    preferredDeliveryDate: DateTime.now().subtract(Duration(days: 2)),
    actualDeliveryDate: DateTime.now().subtract(Duration(days: 1)),
  ),
]; 