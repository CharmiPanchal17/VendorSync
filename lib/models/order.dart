class Order {
  final String id;
  final String productName;
  final int quantity;
  final String supplierName;
  final String vendorEmail;
  final String status;
  final DateTime preferredDeliveryDate;
  final DateTime? actualDeliveryDate;

  Order({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.supplierName,
    required this.vendorEmail,
    required this.status,
    required this.preferredDeliveryDate,
    this.actualDeliveryDate,
  });
} 