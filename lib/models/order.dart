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
  final String vendorEmail;
  // New threshold-related properties
  final int thresholdLevel;
  final bool thresholdNotificationsEnabled;
  final DateTime? lastThresholdAlert;
  final int suggestedOrderQuantity;

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
    required this.vendorEmail,
    this.thresholdLevel = 0,
    this.thresholdNotificationsEnabled = true,
    this.lastThresholdAlert,
    this.suggestedOrderQuantity = 0,
  });

  bool get isLowStock => currentStock <= minimumStock;
  bool get needsRestock => currentStock <= minimumStock * 1.2;
  bool get isAtThreshold => currentStock <= thresholdLevel;
  bool get isCriticalStock => currentStock <= (minimumStock * 0.5);
  double get stockPercentage => currentStock / maximumStock;
  
  int get totalDelivered => deliveryHistory.fold(0, (sum, record) => sum + record.quantity);
  int get totalDeliveries => deliveryHistory.length;
  
  // Threshold status methods
  ThresholdStatus get thresholdStatus {
    if (isCriticalStock) return ThresholdStatus.critical;
    if (isAtThreshold) return ThresholdStatus.warning;
    if (needsRestock) return ThresholdStatus.info;
    return ThresholdStatus.normal;
  }
  
  // Calculate suggested order quantity based on historical data
  int calculateSuggestedOrderQuantity() {
    if (deliveryHistory.isEmpty) return minimumStock;
    
    // Calculate average daily usage from recent deliveries
    final recentDeliveries = deliveryHistory
        .where((record) => record.deliveryDate.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();
    
    if (recentDeliveries.isEmpty) return minimumStock;
    
    final totalQuantity = recentDeliveries.fold(0, (sum, record) => sum + record.quantity);
    final avgDailyUsage = totalQuantity / 30; // Assume 30 days
    
    // Order enough to last 2 weeks plus safety margin
    final suggestedQuantity = (avgDailyUsage * 14 * 1.2).round();
    return suggestedQuantity > 0 ? suggestedQuantity : minimumStock;
  }
}

enum ThresholdStatus {
  normal,
  info,
  warning,
  critical,
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
  final String vendorEmail;

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
    required this.vendorEmail,
  });
} 