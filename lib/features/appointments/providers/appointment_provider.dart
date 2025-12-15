import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../core/constants/app_constants.dart';

class AppointmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Duruma göre filtrelenmiş randevular
  List<AppointmentModel> getPendingAppointments() {
    return _appointments.where((apt) => apt.isPending).toList();
  }

  List<AppointmentModel> getConfirmedAppointments() {
    return _appointments.where((apt) => apt.isConfirmed).toList();
  }

  List<AppointmentModel> getCompletedAppointments() {
    return _appointments.where((apt) => apt.isCompleted).toList();
  }

  // İşletme randevularını yükle
  Future<void> loadBusinessAppointments(String businessId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('businessId', isEqualTo: businessId)
          .orderBy('appointmentDate', descending: false)
          .get();

      _appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Randevular yüklenirken hata oluştu: $e';
      print('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Randevu oluştur (herkese açık)
  Future<bool> createAppointment({
    required String businessId,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final appointmentData = {
        'businessId': businessId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'status': 'pending',
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .add(appointmentData);

      // Eğer mevcut işletme randevuları yüklüyse, yeniden yükle
      if (_appointments.isNotEmpty && _appointments.first.businessId == businessId) {
        await loadBusinessAppointments(businessId);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Randevu oluşturulurken hata oluştu: $e';
      print('Error creating appointment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Randevu durumunu güncelle
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update({'status': newStatus});

      // Listeyi güncelle
      final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(status: newStatus);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Randevu güncellenirken hata oluştu: $e';
      print('Error updating appointment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Randevu sil
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .delete();

      _appointments.removeWhere((apt) => apt.id == appointmentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Randevu silinirken hata oluştu: $e';
      print('Error deleting appointment: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

