import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String barcode;
  final String sku;
  final String description;
  final double price;
  final String unit; // adet, kg, litre, metre, m², m³
  final List<String> imageUrls;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.sku,
    required this.description,
    required this.price,
    required this.unit,
    this.imageUrls = const [],
    this.category = 'Genel',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isActive = true,
    this.metadata,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      barcode: data['barcode'] ?? '',
      sku: data['sku'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? 'adet',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? 'Genel',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'sku': sku,
      'description': description,
      'price': price,
      'unit': unit,
      'imageUrls': imageUrls,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? barcode,
    String? sku,
    String? description,
    double? price,
    String? unit,
    List<String>? imageUrls,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}
