import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/credit_model.dart';
import '../../../core/constants/app_constants.dart';

class CreditProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CreditModel> _credits = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CreditModel> get credits => _credits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Aktif veresiyeler (ödenmemiş ve vadesi geçmemiş)
  List<CreditModel> get activeCredits => _credits
      .where((credit) => !credit.isPaid && !credit.isOverdue)
      .toList();

  // Ödenmiş veresiyeler
  List<CreditModel> get paidCredits =>
      _credits.where((credit) => credit.isPaid).toList();

  // Vadesi geçen veresiyeler
  List<CreditModel> get overdueCredits =>
      _credits.where((credit) => credit.isOverdue).toList();

  // Toplam veresiye tutarı
  double get totalCreditAmount =>
      _credits.fold(0.0, (sum, credit) => sum + credit.remainingAmount);

  // Toplam aktif veresiye sayısı
  int get activeCreditCount => activeCredits.length;

  // Veresiye kayıtlarını yükle
  Future<void> loadCredits() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection(AppConstants.creditCollection)
          .orderBy('createdAt', descending: true)
          .get();

      _credits = snapshot.docs
          .map((doc) => CreditModel.fromFirestore(doc))
          .toList();

      // Vadesi geçen kayıtları otomatik güncelle
      await _updateOverdueCredits();
    } catch (e) {
      _errorMessage = 'Veresiye kayıtları yüklenirken hata oluştu: $e';
      print('Error loading credits: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vadesi geçen kayıtları güncelle
  Future<void> _updateOverdueCredits() async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (final credit in _credits) {
      if (credit.dueDate != null &&
          now.isAfter(credit.dueDate!) &&
          credit.remainingAmount > 0 &&
          credit.status != 'overdue') {
        final docRef = _firestore
            .collection(AppConstants.creditCollection)
            .doc(credit.id);
        batch.update(docRef, {'status': 'overdue'});
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
      // Listeyi yeniden yükle
      await loadCredits();
    }
  }

  // Yeni veresiye ekle
  Future<String> addCredit({
    required String customerName,
    required String customerSurname,
    required String customerPhone,
    required List<CreditItem> items,
    required double totalAmount,
    DateTime? dueDate,
    String notes = '',
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credit = CreditModel(
        id: '', // Firestore tarafından atanacak
        customerName: customerName,
        customerSurname: customerSurname,
        customerPhone: customerPhone,
        items: items,
        totalAmount: totalAmount,
        paidAmount: 0.0,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        status: 'active',
        notes: notes,
        createdBy: createdBy,
        payments: [],
      );

      final docRef = await _firestore
          .collection(AppConstants.creditCollection)
          .add(credit.toFirestore());

      // Listeyi yeniden yükle
      await loadCredits();

      return docRef.id;
    } catch (e) {
      _errorMessage = 'Veresiye eklenirken hata oluştu: $e';
      print('Error adding credit: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Veresiye güncelle
  Future<void> updateCredit(String creditId, CreditModel credit) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection(AppConstants.creditCollection)
          .doc(creditId)
          .update(credit.toFirestore());

      // Listeyi yeniden yükle
      await loadCredits();
    } catch (e) {
      _errorMessage = 'Veresiye güncellenirken hata oluştu: $e';
      print('Error updating credit: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Veresiye sil
  Future<void> deleteCredit(String creditId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection(AppConstants.creditCollection)
          .doc(creditId)
          .delete();

      // Listeyi yeniden yükle
      await loadCredits();
    } catch (e) {
      _errorMessage = 'Veresiye silinirken hata oluştu: $e';
      print('Error deleting credit: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ödeme ekle
  Future<void> addPayment({
    required String creditId,
    required double amount,
    required String method,
    String notes = '',
    required String receivedBy,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Mevcut veresiyeyi bul
      final creditIndex = _credits.indexWhere((c) => c.id == creditId);
      if (creditIndex == -1) {
        throw Exception('Veresiye kaydı bulunamadı');
      }

      final credit = _credits[creditIndex];

      // Yeni ödeme oluştur
      final payment = Payment(
        amount: amount,
        date: DateTime.now(),
        method: method,
        notes: notes,
        receivedBy: receivedBy,
      );

      // Güncel ödeme listesi ve toplam
      final updatedPayments = [...credit.payments, payment];
      final newPaidAmount = credit.paidAmount + amount;
      final newRemainingAmount = credit.totalAmount - newPaidAmount;

      // Durumu güncelle
      String newStatus = credit.status;
      if (newRemainingAmount <= 0) {
        newStatus = 'paid';
      }

      // Firestore'a güncelle
      await _firestore
          .collection(AppConstants.creditCollection)
          .doc(creditId)
          .update({
        'payments': updatedPayments.map((p) => p.toMap()).toList(),
        'paidAmount': newPaidAmount,
        'remainingAmount': newRemainingAmount,
        'status': newStatus,
      });

      // Listeyi yeniden yükle
      await loadCredits();
    } catch (e) {
      _errorMessage = 'Ödeme eklenirken hata oluştu: $e';
      print('Error adding payment: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Müşteri adına göre veresiye ara
  List<CreditModel> searchCredits(String query) {
    if (query.isEmpty) return _credits;

    query = query.toLowerCase().trim();
    return _credits.where((credit) {
      return credit.customerFullName.toLowerCase().contains(query) ||
          credit.customerPhone.contains(query);
    }).toList();
  }

  // ID ile veresiye bul
  CreditModel? getCreditById(String creditId) {
    try {
      return _credits.firstWhere((credit) => credit.id == creditId);
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
