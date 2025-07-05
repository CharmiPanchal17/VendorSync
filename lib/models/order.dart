class Order {
  final String id;
  final String productName;
  final int quantity;
  final String supplierName;
  final String supplierEmail;
  final String status;
  final DateTime preferredDeliveryDate;
  final DateTime? actualDeliveryDate;
  final double? unitPrice;
  final String? notes;
  final bool isAutoOrder;

  Order({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.supplierName,
    required this.supplierEmail,
    required this.status,
    required this.preferredDeliveryDate,
    this.actualDeliveryDate,
    this.unitPrice,
    this.notes,
    this.isAutoOrder = false,
  });
}

class StockItem {
  final String id;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final List<DeliveryRecord> deliveryHistory;
  final String? primarySupplier;
  final String? primarySupplierEmail;
  final DateTime? firstDeliveryDate;
  final DateTime? lastDeliveryDate;
  final bool autoOrderEnabled;
  final double? averageUnitPrice;

  StockItem({
    required this.id,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.deliveryHistory,
    this.primarySupplier,
    this.primarySupplierEmail,
    this.firstDeliveryDate,
    this.lastDeliveryDate,
    this.autoOrderEnabled = false,
    this.averageUnitPrice,
  });

  bool get isLowStock => currentStock <= minimumStock;
  bool get needsRestock => currentStock <= minimumStock * 1.2;
  double get stockPercentage => currentStock / maximumStock;
  
  int get totalDelivered => deliveryHistory.fold(0, (sum, record) => sum + record.quantity);
  int get totalDeliveries => deliveryHistory.length;
}

class DeliveryRecord {
  final String id;
  final String orderId;
  final String productName;
  final int quantity;
  final String supplierName;
  final String supplierEmail;
  final DateTime deliveryDate;
  final double? unitPrice;
  final String? notes;
  final String status;

  DeliveryRecord({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.supplierName,
    required this.supplierEmail,
    required this.deliveryDate,
    this.unitPrice,
    this.notes,
    required this.status,
  });
} 