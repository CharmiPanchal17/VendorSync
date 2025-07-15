import 'package:cloud_firestore/cloud_firestore.dart';

class SalesItem {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime soldAt;
  final String? notes;

  SalesItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.soldAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'soldAt': soldAt,
      'notes': notes,
    };
  }

  factory SalesItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime soldAt;
    if (map['soldAt'] is Timestamp) {
      soldAt = (map['soldAt'] as Timestamp).toDate();
    } else if (map['soldAt'] is DateTime) {
      soldAt = map['soldAt'] as DateTime;
    } else {
      soldAt = DateTime.now();
    }

    return SalesItem(
      id: id,
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      soldAt: soldAt,
      notes: map['notes'],
    );
  }
}

class SalesInvoice {
  final String id;
  final String invoiceNumber;
  final List<SalesItem> items;
  final DateTime createdAt;
  final double totalAmount;
  final String vendorEmail;
  final String? notes;
  final String status; // 'draft', 'completed', 'cancelled'

  SalesInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.createdAt,
    required this.totalAmount,
    required this.vendorEmail,
    this.notes,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt,
      'totalAmount': totalAmount,
      'vendorEmail': vendorEmail,
      'notes': notes,
      'status': status,
    };
  }

  factory SalesInvoice.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

    final itemsData = map['items'] as List<dynamic>? ?? [];
    final items = itemsData.asMap().entries.map((entry) {
      final itemData = entry.value as Map<String, dynamic>;
      return SalesItem.fromMap('item_${entry.key}', itemData);
    }).toList();

    return SalesInvoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      items: items,
      createdAt: createdAt,
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      vendorEmail: map['vendorEmail'] ?? '',
      notes: map['notes'],
      status: map['status'] ?? 'completed',
    );
  }
}

class SalesRecord {
  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime soldAt;
  final String invoiceId;
  final String vendorEmail;
  final String? notes;

  SalesRecord({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.soldAt,
    required this.invoiceId,
    required this.vendorEmail,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'soldAt': soldAt,
      'invoiceId': invoiceId,
      'vendorEmail': vendorEmail,
      'notes': notes,
    };
  }

  factory SalesRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime soldAt;
    if (map['soldAt'] is Timestamp) {
      soldAt = (map['soldAt'] as Timestamp).toDate();
    } else if (map['soldAt'] is DateTime) {
      soldAt = map['soldAt'] as DateTime;
    } else {
      soldAt = DateTime.now();
    }

    return SalesRecord(
      id: id,
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      soldAt: soldAt,
      invoiceId: map['invoiceId'] ?? '',
      vendorEmail: map['vendorEmail'] ?? '',
      notes: map['notes'],
    );
  }
} 