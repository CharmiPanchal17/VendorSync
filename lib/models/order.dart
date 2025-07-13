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
  
  // Calculate suggested order quantity based on multiple factors
  int calculateSuggestedOrderQuantity() {
    // Base calculation using delivery history
    final baseQuantity = _calculateBaseQuantity();
    
    // Adjust based on current stock levels
    final stockAdjustment = _calculateStockAdjustment();
    
    // Adjust based on seasonal trends (if available)
    final seasonalAdjustment = _calculateSeasonalAdjustment();
    
    // Adjust based on supplier lead time
    final leadTimeAdjustment = _calculateLeadTimeAdjustment();
    
    // Adjust based on demand patterns
    final demandAdjustment = _calculateDemandAdjustment();
    
    // Combine all factors with weighted importance
    final suggestedQuantity = (
      baseQuantity * 0.4 +           // 40% weight to base calculation
      stockAdjustment * 0.2 +        // 20% weight to stock levels
      seasonalAdjustment * 0.1 +     // 10% weight to seasonal trends
      leadTimeAdjustment * 0.2 +     // 20% weight to lead time
      demandAdjustment * 0.1         // 10% weight to demand patterns
    ).round();
    
    // Ensure minimum order quantity and apply safety margin
    final finalQuantity = suggestedQuantity > 0 ? suggestedQuantity : minimumStock;
    return (finalQuantity * 1.1).round(); // 10% safety margin
  }

  // Calculate base quantity from delivery history
  int _calculateBaseQuantity() {
    if (deliveryHistory.isEmpty) return minimumStock;
    
    // Get recent deliveries (last 60 days for better accuracy)
    final recentDeliveries = deliveryHistory
        .where((record) => record.deliveryDate.isAfter(DateTime.now().subtract(const Duration(days: 60))))
        .toList();
    
    if (recentDeliveries.isEmpty) return minimumStock;
    
    // Calculate average daily usage
    final totalQuantity = recentDeliveries.fold(0, (sum, record) => sum + record.quantity);
    final daysSinceFirstDelivery = DateTime.now().difference(recentDeliveries.first.deliveryDate).inDays;
    final avgDailyUsage = daysSinceFirstDelivery > 0 ? totalQuantity / daysSinceFirstDelivery : totalQuantity / 30;
    
    // Order enough to last 3 weeks (21 days) for better planning
    return (avgDailyUsage * 21).round();
  }

  // Adjust based on current stock levels
  int _calculateStockAdjustment() {
    final stockRatio = currentStock / maximumStock;
    
    if (stockRatio < 0.2) {
      // Very low stock - increase order
      return (minimumStock * 0.5).round();
    } else if (stockRatio < 0.4) {
      // Low stock - moderate increase
      return (minimumStock * 0.3).round();
    } else if (stockRatio > 0.8) {
      // High stock - reduce order
      return -(minimumStock * 0.2).round();
    }
    
    return 0; // No adjustment needed
  }

  // Adjust based on seasonal trends and holiday periods
  int _calculateSeasonalAdjustment() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentDay = now.day;
    
    // Check if this is a food item (you can enhance this logic)
    final isFoodItem = _isFoodItem();
    
    if (!isFoodItem) return 0; // No seasonal adjustment for non-food items
    
    // Calculate days until next major holiday
    final daysUntilEaster = _getDaysUntilEaster(now);
    final daysUntilIdd = _getDaysUntilIdd(now);
    final daysUntilChristmas = _getDaysUntilChristmas(now);
    
    // Determine the closest upcoming holiday
    final closestHoliday = _getClosestHoliday(daysUntilEaster, daysUntilIdd, daysUntilChristmas);
    
    if (closestHoliday == null) return 0; // No upcoming holiday
    
    // Calculate seasonal adjustment based on proximity to holiday
    return _calculateHolidayAdjustment(closestHoliday);
  }

  // Check if the product is a food item
  bool _isFoodItem() {
    // List of food-related keywords
    final foodKeywords = [
      'rice', 'flour', 'sugar', 'oil', 'milk', 'bread', 'meat', 'chicken', 'beef', 'fish',
      'vegetables', 'fruits', 'eggs', 'cheese', 'butter', 'pasta', 'noodles', 'sauce',
      'spices', 'herbs', 'beans', 'lentils', 'cereal', 'juice', 'soda', 'chocolate',
      'candy', 'snacks', 'cookies', 'cake', 'pastry', 'biscuits', 'tea', 'coffee',
      'water', 'beverage', 'drink', 'food', 'grocery', 'ingredient'
    ];
    
    final productNameLower = productName.toLowerCase();
    return foodKeywords.any((keyword) => productNameLower.contains(keyword));
  }

  // Get days until Easter (simplified calculation)
  int _getDaysUntilEaster(DateTime now) {
    // Easter typically falls between March 22 and April 25
    // This is a simplified calculation - you might want to use a more accurate algorithm
    final currentYear = now.year;
    final easterDate = _calculateEasterDate(currentYear);
    
    // If Easter has passed this year, calculate for next year
    if (now.isAfter(easterDate)) {
      final nextEasterDate = _calculateEasterDate(currentYear + 1);
      return nextEasterDate.difference(now).inDays;
    }
    
    return easterDate.difference(now).inDays;
  }

  // Calculate Easter date using Meeus/Jones/Butcher algorithm
  DateTime _calculateEasterDate(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    
    return DateTime(year, month, day);
  }

  // Get days until Eid al-Fitr (Idd)
  int _getDaysUntilIdd(DateTime now) {
    // Eid al-Fitr is typically 10-11 days after the start of Ramadan
    // This is a simplified calculation - actual dates vary by lunar calendar
    final currentYear = now.year;
    
    // Approximate dates for Eid al-Fitr (you might want to use a more accurate Islamic calendar)
    final iddDates = [
      DateTime(currentYear, 4, 21), // Approximate for 2024
      DateTime(currentYear, 4, 10), // Approximate for 2023
      DateTime(currentYear, 5, 2),  // Approximate for 2025
    ];
    
    // Find the next Eid al-Fitr date
    for (final iddDate in iddDates) {
      if (now.isBefore(iddDate)) {
        return iddDate.difference(now).inDays;
      }
    }
    
    // If all dates have passed, calculate for next year
    return DateTime(currentYear + 1, 4, 21).difference(now).inDays;
  }

  // Get days until Christmas
  int _getDaysUntilChristmas(DateTime now) {
    final currentYear = now.year;
    final christmasDate = DateTime(currentYear, 12, 25);
    
    // If Christmas has passed this year, calculate for next year
    if (now.isAfter(christmasDate)) {
      final nextChristmasDate = DateTime(currentYear + 1, 12, 25);
      return nextChristmasDate.difference(now).inDays;
    }
    
    return christmasDate.difference(now).inDays;
  }

  // Get the closest upcoming holiday
  Map<String, dynamic>? _getClosestHoliday(int daysUntilEaster, int daysUntilIdd, int daysUntilChristmas) {
    final holidays = <Map<String, dynamic>>[
      {'name': 'Easter', 'days': daysUntilEaster},
      {'name': 'Idd', 'days': daysUntilIdd},
      {'name': 'Christmas', 'days': daysUntilChristmas},
    ];
    
    // Filter holidays that are within 60 days and find the closest
    final upcomingHolidays = holidays.where((holiday) => (holiday['days'] as int) <= 60).toList();
    
    if (upcomingHolidays.isEmpty) return null;
    
    // Return the closest holiday
    upcomingHolidays.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
    return {
      'name': upcomingHolidays.first['name'] as String,
      'days': upcomingHolidays.first['days'] as int,
    };
  }

  // Calculate holiday adjustment based on proximity
  int _calculateHolidayAdjustment(Map<String, int> holiday) {
    final daysUntilHoliday = holiday['days']!;
    final holidayName = holiday['name']!;
    
    // Base adjustment factors for different holidays
    final baseAdjustments = {
      'Easter': 0.4,    // 40% increase for Easter
      'Idd': 0.5,       // 50% increase for Idd
      'Christmas': 0.6, // 60% increase for Christmas
    };
    
    final baseAdjustment = baseAdjustments[holidayName] ?? 0.3;
    
    // Adjust based on proximity to holiday
    if (daysUntilHoliday <= 7) {
      // Very close to holiday - maximum adjustment
      return (minimumStock * baseAdjustment * 1.5).round();
    } else if (daysUntilHoliday <= 14) {
      // Close to holiday - high adjustment
      return (minimumStock * baseAdjustment * 1.2).round();
    } else if (daysUntilHoliday <= 30) {
      // Approaching holiday - moderate adjustment
      return (minimumStock * baseAdjustment).round();
    } else if (daysUntilHoliday <= 60) {
      // Planning for holiday - slight adjustment
      return (minimumStock * baseAdjustment * 0.7).round();
    }
    
    return 0;
  }

  // Adjust based on supplier lead time
  int _calculateLeadTimeAdjustment() {
    // Assume average lead time of 7 days
    // Order extra to cover lead time period
    if (deliveryHistory.isEmpty) return minimumStock;
    
    final recentDeliveries = deliveryHistory
        .where((record) => record.deliveryDate.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();
    
    if (recentDeliveries.isEmpty) return minimumStock;
    
    final totalQuantity = recentDeliveries.fold(0, (sum, record) => sum + record.quantity);
    final avgDailyUsage = totalQuantity / 30;
    
    // Order extra for 7 days of lead time
    return (avgDailyUsage * 7).round();
  }

  // Adjust based on demand patterns and trends including slope analysis
  int _calculateDemandAdjustment() {
    // This would ideally use sales history data
    // For now, use delivery patterns to estimate demand
    
    if (deliveryHistory.isEmpty) return 0;
    
    // Get recent deliveries to analyze trends
    final recentDeliveries = deliveryHistory
        .where((record) => record.deliveryDate.isAfter(DateTime.now().subtract(const Duration(days: 90))))
        .toList();
    
    if (recentDeliveries.length < 3) return 0;
    
    // Sort by date to analyze trends
    recentDeliveries.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    
    // Calculate slope using linear regression
    final slope = _calculateTrendSlope(recentDeliveries);
    
    // Calculate traditional demand change
    final firstHalf = recentDeliveries.take(recentDeliveries.length ~/ 2).toList();
    final secondHalf = recentDeliveries.skip(recentDeliveries.length ~/ 2).toList();
    
    final firstHalfAvg = firstHalf.fold(0, (sum, record) => sum + record.quantity) / firstHalf.length;
    final secondHalfAvg = secondHalf.fold(0, (sum, record) => sum + record.quantity) / secondHalf.length;
    
    final demandChange = secondHalfAvg - firstHalfAvg;
    final demandChangePercent = firstHalfAvg > 0 ? demandChange / firstHalfAvg : 0.0;
    
    // Combine slope analysis with traditional demand change
    final slopeAdjustment = _calculateSlopeAdjustment(slope);
    final traditionalAdjustment = _calculateTraditionalAdjustment(demandChangePercent);
    
    // Weight slope analysis more heavily for recent trends
    return ((slopeAdjustment * 0.7) + (traditionalAdjustment * 0.3)).round();
  }

  // Calculate the slope of the trend line using linear regression
  double _calculateTrendSlope(List<DeliveryRecord> deliveries) {
    if (deliveries.length < 2) return 0.0;
    
    // Convert dates to days since first delivery for x-axis
    final firstDate = deliveries.first.deliveryDate;
    final dataPoints = deliveries.map((record) {
      final daysSinceFirst = record.deliveryDate.difference(firstDate).inDays;
      return {'x': daysSinceFirst.toDouble(), 'y': record.quantity.toDouble()};
    }).toList();
    
    // Calculate linear regression slope
    final n = dataPoints.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (final point in dataPoints) {
      sumX += point['x']!;
      sumY += point['y']!;
      sumXY += point['x']! * point['y']!;
      sumX2 += point['x']! * point['x']!;
    }
    
    final denominator = (n * sumX2) - (sumX * sumX);
    if (denominator == 0) return 0.0;
    
    final slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    return slope;
  }

  // Calculate adjustment based on slope analysis
  int _calculateSlopeAdjustment(double slope) {
    // Normalize slope to daily change
    final dailyChange = slope;
    
    // Calculate how much the trend suggests we should adjust
    if (dailyChange > 2.0) {
      // Steep upward trend - significant increase needed
      return (minimumStock * 0.5).round();
    } else if (dailyChange > 1.0) {
      // Moderate upward trend - moderate increase
      return (minimumStock * 0.3).round();
    } else if (dailyChange > 0.5) {
      // Slight upward trend - small increase
      return (minimumStock * 0.15).round();
    } else if (dailyChange < -2.0) {
      // Steep downward trend - significant decrease
      return -(minimumStock * 0.4).round();
    } else if (dailyChange < -1.0) {
      // Moderate downward trend - moderate decrease
      return -(minimumStock * 0.25).round();
    } else if (dailyChange < -0.5) {
      // Slight downward trend - small decrease
      return -(minimumStock * 0.1).round();
    }
    
    return 0; // Stable trend - no adjustment
  }

  // Calculate adjustment based on traditional demand change analysis
  int _calculateTraditionalAdjustment(double demandChangePercent) {
    if (demandChangePercent > 0.2) {
      // Increasing demand - order more
      return (minimumStock * 0.3).round();
    } else if (demandChangePercent < -0.2) {
      // Decreasing demand - order less
      return -(minimumStock * 0.2).round();
    }
    
    return 0; // Stable demand - no adjustment
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