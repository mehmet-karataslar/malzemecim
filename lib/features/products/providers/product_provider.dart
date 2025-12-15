import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/product_model.dart';
import '../../../core/constants/app_constants.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Kategoriye göre filtrelenmiş ürünler
  List<ProductModel> getProductsByCategory(String category) {
    if (category.isEmpty || category == 'Tümü') {
      return _products;
    }
    return _products.where((product) => product.category == category).toList();
  }

  // Arama - Gelişmiş arama algoritması
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;

    query = query.toLowerCase().trim();

    // Tam eşleşme öncelikli sonuçlar
    final exactMatches = <ProductModel>[];
    final partialMatches = <ProductModel>[];

    for (final product in _products) {
      final name = product.name.toLowerCase();
      final brand = product.brand.toLowerCase();
      final category = product.category.toLowerCase();
      final barcode = product.barcode.toLowerCase();
      final description = product.description.toLowerCase();

      // Tam eşleşme kontrolü (yüksek öncelik)
      if (name == query ||
          brand == query ||
          category == query ||
          barcode == query) {
        exactMatches.add(product);
        continue;
      }

      // Kısmi eşleşme kontrolü
      if (name.contains(query) ||
          brand.contains(query) ||
          category.contains(query) ||
          barcode.contains(query) ||
          description.contains(query)) {
        partialMatches.add(product);
      }
    }

    // Tam eşleşmeleri önce, sonra kısmi eşleşmeleri döndür
    return [...exactMatches, ...partialMatches];
  }

  // Düşük stok ürünleri
  List<ProductModel> getLowStockProducts() {
    return _products
        .where((product) => product.stock <= product.minStock)
        .toList();
  }

  // Ürünleri yükle
  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Ürünler yüklenirken hata oluştu: $e';
      print('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni ürün ekle
  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // SKU oluştur
      final sku = 'PRD${DateTime.now().millisecondsSinceEpoch}';
      productData['sku'] = sku;

      // Firestore'a ürün ekle
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(productData);

      // Stok kaydı oluştur
      await _firestore
          .collection(AppConstants.inventoryCollection)
          .doc(docRef.id)
          .set({
            'productId': docRef.id,
            'currentStock': productData['stock'],
            'minimumStock': productData['minStock'],
            'maximumStock':
                (productData['stock'] as double) * 10, // Varsayılan max stok
            'location': 'Ana Depo',
            'lastUpdated': FieldValue.serverTimestamp(),
            'lastUpdatedBy': productData['createdBy'],
            'movements': [],
          });

      // Yerel listeyi güncelle
      await loadProducts();

      return docRef.id;
    } catch (e) {
      _errorMessage = 'Ürün eklenirken hata oluştu: $e';
      print('Error adding product: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ürün güncelle
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      productData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update(productData);

      // Yerel listeyi güncelle
      await loadProducts();
    } catch (e) {
      _errorMessage = 'Ürün güncellenirken hata oluştu: $e';
      print('Error updating product: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ürün sil (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Yerel listeyi güncelle
      await loadProducts();
    } catch (e) {
      _errorMessage = 'Ürün silinirken hata oluştu: $e';
      print('Error deleting product: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stok güncelle
  Future<void> updateStock(
    String productId,
    double newStock,
    String reason,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final batch = _firestore.batch();

      // Ürün stokunu güncelle
      final productRef = _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId);

      batch.update(productRef, {
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Stok hareketi kaydet
      final inventoryRef = _firestore
          .collection(AppConstants.inventoryCollection)
          .doc(productId);

      batch.update(inventoryRef, {
        'currentStock': newStock,
        'lastUpdated': FieldValue.serverTimestamp(),
        'movements': FieldValue.arrayUnion([
          {
            'date': Timestamp.now(),
            'type': 'manual_update',
            'quantity': newStock,
            'reason': reason,
          },
        ]),
      });

      await batch.commit();

      // Yerel listeyi güncelle
      await loadProducts();
    } catch (e) {
      _errorMessage = 'Stok güncellenirken hata oluştu: $e';
      print('Error updating stock: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ID ile ürün bul
  ProductModel? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Barkod ile ürün bul
  ProductModel? getProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((product) => product.barcode == barcode);
    } catch (e) {
      return null;
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
