import 'package:cloud_firestore/cloud_firestore.dart';

class SalesModel {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime saleDate;
  final String createdBy;
  final String? creditId; // Veresiyeden gelen satış için
  final String saleType; // 'cash', 'credit', 'card'

  SalesModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.saleDate,
    required this.createdBy,
    this.creditId,
    this.saleType = 'cash',
  });

  factory SalesModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SalesModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      saleDate: (data['saleDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      creditId: data['creditId'],
      saleType: data['saleType'] ?? 'cash',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'saleDate': Timestamp.fromDate(saleDate),
      'createdBy': createdBy,
      'creditId': creditId,
      'saleType': saleType,
    };
  }
}
