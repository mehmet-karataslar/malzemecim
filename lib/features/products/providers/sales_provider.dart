import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/sales_model.dart';

class SalesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SalesModel> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<SalesModel> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Satış ekle
  Future<String> addSale({
    required String productId,
    required String productName,
    required double quantity,
    required double unitPrice,
    required String createdBy,
    String? creditId,
    String saleType = 'cash',
  }) async {
    try {
      final sale = SalesModel(
        id: '',
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: quantity * unitPrice,
        saleDate: DateTime.now(),
        createdBy: createdBy,
        creditId: creditId,
        saleType: saleType,
      );

      final docRef = await _firestore
          .collection('sales')
          .add(sale.toFirestore());

      return docRef.id;
    } catch (e) {
      _errorMessage = 'Satış eklenirken hata oluştu: $e';
      print('Error adding sale: $e');
      rethrow;
    }
  }

  // Ürüne göre satışları getir
  Future<List<SalesModel>> getSalesByProduct(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('sales')
          .where('productId', isEqualTo: productId)
          .orderBy('saleDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SalesModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting sales by product: $e');
      return [];
    }
  }

  // Haftalık satış sayısı
  Future<Map<String, dynamic>> getWeeklySales(String productId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    try {
      final snapshot = await _firestore
          .collection('sales')
          .where('productId', isEqualTo: productId)
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      double totalQuantity = 0;
      double totalAmount = 0;
      
      for (var doc in snapshot.docs) {
        final sale = SalesModel.fromFirestore(doc);
        totalQuantity += sale.quantity;
        totalAmount += sale.totalPrice;
      }

      return {
        'count': snapshot.docs.length,
        'quantity': totalQuantity,
        'amount': totalAmount,
      };
    } catch (e) {
      print('Error getting weekly sales: $e');
      return {'count': 0, 'quantity': 0.0, 'amount': 0.0};
    }
  }

  // Aylık satış sayısı
  Future<Map<String, dynamic>> getMonthlySales(String productId) async {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    
    try {
      final snapshot = await _firestore
          .collection('sales')
          .where('productId', isEqualTo: productId)
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
          .get();

      double totalQuantity = 0;
      double totalAmount = 0;
      
      for (var doc in snapshot.docs) {
        final sale = SalesModel.fromFirestore(doc);
        totalQuantity += sale.quantity;
        totalAmount += sale.totalPrice;
      }

      return {
        'count': snapshot.docs.length,
        'quantity': totalQuantity,
        'amount': totalAmount,
      };
    } catch (e) {
      print('Error getting monthly sales: $e');
      return {'count': 0, 'quantity': 0.0, 'amount': 0.0};
    }
  }

  // Yıllık satış sayısı
  Future<Map<String, dynamic>> getYearlySales(String productId) async {
    final now = DateTime.now();
    final yearAgo = DateTime(now.year - 1, now.month, now.day);
    
    try {
      final snapshot = await _firestore
          .collection('sales')
          .where('productId', isEqualTo: productId)
          .where('saleDate', isGreaterThanOrEqualTo: Timestamp.fromDate(yearAgo))
          .get();

      double totalQuantity = 0;
      double totalAmount = 0;
      
      for (var doc in snapshot.docs) {
        final sale = SalesModel.fromFirestore(doc);
        totalQuantity += sale.quantity;
        totalAmount += sale.totalPrice;
      }

      return {
        'count': snapshot.docs.length,
        'quantity': totalQuantity,
        'amount': totalAmount,
      };
    } catch (e) {
      print('Error getting yearly sales: $e');
      return {'count': 0, 'quantity': 0.0, 'amount': 0.0};
    }
  }

  // Tüm satış istatistiklerini getir
  Future<Map<String, Map<String, dynamic>>> getAllSalesStats(String productId) async {
    final weekly = await getWeeklySales(productId);
    final monthly = await getMonthlySales(productId);
    final yearly = await getYearlySales(productId);

    return {
      'weekly': weekly,
      'monthly': monthly,
      'yearly': yearly,
    };
  }

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
