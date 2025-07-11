# 🚀 Auto-Reorder System Implementation Guide

## Overview

The VendorSync POS system now includes an intelligent auto-reorder feature that automatically monitors stock levels and creates orders when thresholds are reached. This system helps vendors maintain optimal inventory levels without manual intervention.

## 🧠 How It Works

### Core Logic

The auto-reorder system implements the following logic:

```dart
void monitorStockAndTriggerOrder(Item item) {
  if (item.stockLevel <= (item.initialStock * item.reorderThreshold)) {
    createSupplierOrder(item);
  }
}
```

### Threshold Calculation

- **Default Threshold**: 20% of maximum stock level
- **Minimum Stock**: Uses the higher of minimum stock or 20% threshold
- **Critical Alert**: 10% threshold triggers immediate notifications

## 📁 File Structure

```
lib/
├── services/
│   ├── auto_reorder_service.dart      # Main auto-reorder logic
│   ├── sales_service.dart             # Enhanced with auto-reorder triggers
│   └── notification_service.dart      # Auto-order notifications
├── widgets/
│   └── auto_reorder_dashboard.dart    # Dashboard widget
└── models/
    └── order.dart                     # Enhanced with auto-order fields
```

## 🔧 Key Components

### 1. AutoReorderService

**Location**: `lib/services/auto_reorder_service.dart`

**Main Functions**:
- `monitorStockAndTriggerOrders()` - Main monitoring function
- `_checkAndTriggerOrder()` - Individual item checking
- `_createAutomaticOrder()` - Order creation logic
- `getAutoOrderStats()` - Statistics and analytics
- `getLowStockItems()` - Low stock alerts

**Usage Example**:
```dart
// Monitor all stock items
await AutoReorderService.monitorStockAndTriggerOrders();

// Get auto-order statistics
final stats = await AutoReorderService.getAutoOrderStats(vendorEmail);

// Get low stock items
final lowStockItems = await AutoReorderService.getLowStockItems(vendorEmail);
```

### 2. Enhanced SalesService

**Location**: `lib/services/sales_service.dart`

**Integration**:
- Automatically triggers stock monitoring after each sale
- Sends critical stock notifications
- Updates stock levels in real-time

**Key Changes**:
```dart
// After updating stock levels
await AutoReorderService.monitorStockAndTriggerOrders();

// Critical stock notifications
if (newStock <= criticalThreshold) {
  await NotificationService.sendStockThresholdNotification(...);
}
```

### 3. Auto-Reorder Dashboard Widget

**Location**: `lib/widgets/auto_reorder_dashboard.dart`

**Features**:
- Real-time auto-order statistics
- Low stock alerts with visual indicators
- Quick action buttons for monitoring and settings
- Integration with vendor dashboard

## 🎯 Implementation Details

### Firestore Collections

#### stock_items
```json
{
  "productName": "Widgets",
  "currentStock": 25,
  "minimumStock": 20,
  "maximumStock": 250,
  "autoOrderEnabled": true,
  "autoOrderQuantity": 250,
  "reorderThreshold": 0.2,
  "vendorEmail": "vendor@example.com",
  "primarySupplier": "Supplier A",
  "primarySupplierEmail": "supplierA@example.com",
  "lastAutoOrderId": "order_123",
  "lastAutoOrderDate": "2024-01-15T10:30:00Z",
  "lastAutoOrderStockLevel": 25
}
```

#### orders (Enhanced)
```json
{
  "productName": "Widgets",
  "quantity": 250,
  "supplierEmail": "supplierA@example.com",
  "vendorEmail": "vendor@example.com",
  "status": "Pending",
  "isAutoOrder": true,
  "autoOrderTriggeredAt": "2024-01-15T10:30:00Z",
  "stockLevelAtTrigger": 25,
  "thresholdLevel": 50,
  "notes": "Auto-generated order due to low stock level"
}
```

### Trigger Points

1. **On Every Sale**: Stock monitoring triggered automatically
2. **Manual Monitoring**: Via dashboard "Monitor Stock" button
3. **Background Tasks**: Can be scheduled for periodic checks
4. **Real-time Streams**: Firestore listeners for immediate updates

### Notification System

#### Auto-Order Notifications
- **Supplier Notification**: Informs supplier of auto-generated order
- **Vendor Notification**: Confirms auto-order creation to vendor
- **Critical Stock Alerts**: Immediate notifications for 10% threshold

#### Notification Types
```dart
// Supplier notification
await NotificationService.notifySupplierOfAutoOrder(
  vendorEmail: vendorEmail,
  supplierEmail: supplierEmail,
  orderId: orderRef.id,
  productName: productName,
  quantity: quantity,
  currentStock: currentStock,
  threshold: threshold,
);

// Vendor notification
await NotificationService.notifyVendorOfAutoOrder(
  vendorEmail: vendorEmail,
  supplierEmail: supplierEmail,
  orderId: orderRef.id,
  productName: productName,
  quantity: quantity,
  currentStock: currentStock,
  threshold: threshold,
);
```

## 🎨 UI Integration

### Vendor Dashboard

The auto-reorder dashboard is integrated into the vendor dashboard with:

- **Statistics Cards**: Total, pending, completed auto-orders
- **Low Stock Alerts**: Visual indicators for items needing attention
- **Quick Actions**: Monitor stock and access settings
- **Real-time Updates**: Live data from Firestore

### Color Scheme

Following the project's maroon theme:
- **Primary**: `Color(0xFF800000)` - Maroon
- **Background**: `Color(0xFFAFFFFF)` - Light cyan
- **Status Colors**: 
  - Red: Critical stock levels
  - Orange: Low stock warnings
  - Green: Healthy stock levels

## 🚀 Usage Instructions

### For Vendors

1. **Enable Auto-Order**: In stock management, enable auto-order for specific items
2. **Set Thresholds**: Configure reorder thresholds (default: 20%)
3. **Monitor Dashboard**: Check auto-reorder dashboard for alerts
4. **Review Orders**: Auto-orders appear in regular order list with `isAutoOrder: true`

### For Suppliers

1. **Receive Notifications**: Get notified of auto-generated orders
2. **Process Orders**: Handle auto-orders same as manual orders
3. **Update Status**: Confirm and deliver auto-orders

### For Developers

1. **Extend Logic**: Modify `AutoReorderService` for custom business rules
2. **Add Triggers**: Implement additional trigger points
3. **Customize UI**: Modify dashboard widget for specific needs
4. **Add Analytics**: Extend statistics and reporting

## 🔧 Configuration Options

### Threshold Settings
```dart
// Custom threshold calculation
static int _calculateReorderThreshold(int minimumStock, int maximumStock) {
  final percentageThreshold = (maximumStock * 0.2).round(); // 20% threshold
  return percentageThreshold > minimumStock ? percentageThreshold : minimumStock;
}
```

### Auto-Order Quantity
```dart
// Default: Maximum stock level
final autoOrderQuantity = data['autoOrderQuantity'] as int? ?? maximumStock;

// Custom: Restore to 80% capacity
final autoOrderQuantity = (maximumStock * 0.8 - currentStock).round();
```

### Notification Settings
```dart
// Critical threshold (10%)
final criticalThreshold = (maximumStock * 0.1).round();

// Warning threshold (20%)
final warningThreshold = (maximumStock * 0.2).round();
```

## 📊 Analytics & Reporting

### Auto-Order Statistics
- Total auto-orders created
- Pending auto-orders
- Completed auto-orders
- Total value of auto-orders
- Auto-order percentage of total orders

### Low Stock Monitoring
- Items below threshold
- Stock percentage levels
- Auto-order status per item
- Historical auto-order data

## 🔒 Security & Validation

### Duplicate Prevention
```dart
// Check for existing pending auto-orders
final existingOrderQuery = await _firestore
    .collection('orders')
    .where('productName', isEqualTo: productName)
    .where('supplierEmail', isEqualTo: supplierEmail)
    .where('status', whereIn: ['Pending', 'Pending Approval'])
    .where('isAutoOrder', isEqualTo: true)
    .get();

if (existingOrderQuery.docs.isNotEmpty) {
  print('[AutoReorder] Auto-order already exists for $productName. Skipping...');
  return;
}
```

### Error Handling
- Graceful failure handling
- Logging for debugging
- Fallback mechanisms
- User notifications for errors

## 🚀 Future Enhancements

### Planned Features
1. **Machine Learning**: Predictive stock level forecasting
2. **Seasonal Adjustments**: Dynamic threshold adjustments
3. **Multi-Supplier Logic**: Automatic supplier selection
4. **Cost Optimization**: Order quantity optimization
5. **Integration APIs**: External inventory system integration

### Extension Points
1. **Custom Triggers**: Business-specific trigger conditions
2. **Workflow Integration**: Approval workflows for auto-orders
3. **Advanced Analytics**: Predictive analytics and reporting
4. **Mobile Notifications**: Push notifications for critical alerts

## 📝 Best Practices

### Implementation
1. **Test Thoroughly**: Test with various stock scenarios
2. **Monitor Performance**: Watch for Firestore query costs
3. **User Training**: Educate users on auto-order features
4. **Documentation**: Keep documentation updated

### Configuration
1. **Start Conservative**: Begin with higher thresholds
2. **Monitor Results**: Track auto-order effectiveness
3. **Adjust Gradually**: Fine-tune based on business needs
4. **Backup Plans**: Maintain manual order capabilities

## 🐛 Troubleshooting

### Common Issues
1. **Auto-orders not triggering**: Check `autoOrderEnabled` flag
2. **Duplicate orders**: Verify duplicate prevention logic
3. **Missing notifications**: Check notification service configuration
4. **Performance issues**: Monitor Firestore query optimization

### Debug Tools
```dart
// Enable debug logging
print('[AutoReorder] Checking $productName: current=$currentStock, threshold=$threshold');

// Monitor stock changes
print('[StockUpdate] $productName: currentStock=$currentStock, quantity=$quantity, newStock=$newStock');
```

---

This auto-reorder system provides a robust, intelligent solution for maintaining optimal inventory levels while reducing manual intervention and preventing stockouts. 