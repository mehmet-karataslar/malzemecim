import 'package:cloud_firestore/cloud_firestore.dart';

class CreditModel {
  final String id;
  final String customerName;
  final String customerSurname;
  final String customerPhone;
  final List<CreditItem> items;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String status; // 'active', 'paid', 'overdue'
  final String notes;
  final String createdBy;
  final List<Payment> payments;

  CreditModel({
    required this.id,
    required this.customerName,
    required this.customerSurname,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.createdAt,
    this.dueDate,
    this.status = 'active',
    this.notes = '',
    required this.createdBy,
    this.payments = const [],
  }) : remainingAmount = totalAmount - paidAmount;

  factory CreditModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CreditModel(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerSurname: data['customerSurname'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CreditItem.fromMap(e))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'active',
      notes: data['notes'] ?? '',
      createdBy: data['createdBy'] ?? '',
      payments: (data['payments'] as List<dynamic>? ?? [])
          .map((e) => Payment.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'customerSurname': customerSurname,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'payments': payments.map((e) => e.toMap()).toList(),
    };
  }

  String get customerFullName => '$customerName $customerSurname';
  bool get isOverdue =>
      dueDate != null &&
      DateTime.now().isAfter(dueDate!) &&
      remainingAmount > 0;
  bool get isPaid => remainingAmount <= 0;

  CreditModel copyWith({
    String? id,
    String? customerName,
    String? customerSurname,
    String? customerPhone,
    List<CreditItem>? items,
    double? totalAmount,
    double? paidAmount,
    DateTime? createdAt,
    DateTime? dueDate,
    String? status,
    String? notes,
    String? createdBy,
    List<Payment>? payments,
  }) {
    return CreditModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerSurname: customerSurname ?? this.customerSurname,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      payments: payments ?? this.payments,
    );
  }
}

class CreditItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final String unit;
  final double totalPrice;

  CreditItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unit,
  }) : totalPrice = quantity * unitPrice;

  factory CreditItem.fromMap(Map<String, dynamic> map) {
    return CreditItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'adet',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unit': unit,
      'totalPrice': totalPrice,
    };
  }
}

class Payment {
  final double amount;
  final DateTime date;
  final String method; // 'cash', 'card', 'transfer'
  final String notes;
  final String receivedBy;

  Payment({
    required this.amount,
    required this.date,
    this.method = 'cash',
    this.notes = '',
    required this.receivedBy,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      method: map['method'] ?? 'cash',
      notes: map['notes'] ?? '',
      receivedBy: map['receivedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'method': method,
      'notes': notes,
      'receivedBy': receivedBy,
    };
  }
}
