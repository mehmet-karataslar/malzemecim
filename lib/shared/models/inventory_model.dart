import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String productId;
  final double currentStock;
  final double minimumStock;
  final double maximumStock;
  final String location; // Depo konumu
  final DateTime lastUpdated;
  final String lastUpdatedBy;
  final List<StockMovement> movements;

  InventoryModel({
    required this.id,
    required this.productId,
    required this.currentStock,
    required this.minimumStock,
    this.maximumStock = 0,
    this.location = 'Ana Depo',
    required this.lastUpdated,
    required this.lastUpdatedBy,
    this.movements = const [],
  });

  factory InventoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InventoryModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      currentStock: (data['currentStock'] ?? 0.0).toDouble(),
      minimumStock: (data['minimumStock'] ?? 0.0).toDouble(),
      maximumStock: (data['maximumStock'] ?? 0.0).toDouble(),
      location: data['location'] ?? 'Ana Depo',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      lastUpdatedBy: data['lastUpdatedBy'] ?? '',
      movements: (data['movements'] as List<dynamic>? ?? [])
          .map((e) => StockMovement.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'location': location,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastUpdatedBy': lastUpdatedBy,
      'movements': movements.map((e) => e.toMap()).toList(),
    };
  }

  // Stok durumu kontrolleri
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  bool get isOverStock => maximumStock > 0 && currentStock > maximumStock;

  InventoryModel copyWith({
    String? id,
    String? productId,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    String? location,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
    List<StockMovement>? movements,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      location: location ?? this.location,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      movements: movements ?? this.movements,
    );
  }
}

class StockMovement {
  final String type; // 'in', 'out', 'adjustment'
  final double quantity;
  final String reason;
  final DateTime date;
  final String userId;
  final String? reference; // Fatura no, sipariş no vb.

  StockMovement({
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
    required this.userId,
    this.reference,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      type: map['type'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      reference: map['reference'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'reference': reference,
    };
  }
}
