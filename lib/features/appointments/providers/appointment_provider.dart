import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/appointment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // Belirli bir günün randevularını getir
  List<AppointmentModel> getAppointmentsForDate(DateTime date) {
    return _appointments.where((appointment) {
      return appointment.appointmentDate.year == date.year &&
             appointment.appointmentDate.month == date.month &&
             appointment.appointmentDate.day == date.day;
    }).toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  // Tarih seçimi
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Randevuları yükle (Realtime Listener)
  void listenToAppointments() {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Sadece bu işletmenin randevularını dinle
      _firestore
          .collection('appointments')
          .where('businessId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        _appointments = snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList();
        
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        _errorMessage = 'Randevular yüklenirken hata: $error';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Beklenmeyen hata: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Randevu Ekle
  Future<void> addAppointment({
    required String customerName,
    required String customerPhone,
    required String businessId, // Seçilen işletme ID'si
    required DateTime date,
    required DateTime time,
    String? customerEmail,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Tarih ve zamanı birleştir
      final appointmentDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final newAppointment = AppointmentModel(
        id: '', // Firestore oluşturacak
        businessId: businessId, // Seçilen işletme ID'si
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        appointmentDate: appointmentDateTime,
        status: 'pending', // Varsayılan bekleyen (işletme onaylayacak)
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('appointments').add(newAppointment.toFirestore());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Randevu eklenemedi: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Randevu Durumu Güncelle
  Future<void> updateStatus(String id, String newStatus) async {
    try {
      await _firestore.collection('appointments').doc(id).update({
        'status': newStatus,
      });
    } catch (e) {
      print('Status update error: $e');
      rethrow;
    }
  }

  // Randevu Sil
  Future<void> deleteAppointment(String id) async {
    try {
      await _firestore.collection('appointments').doc(id).delete();
    } catch (e) {
      print('Delete error: $e');
      rethrow;
    }
  }
}

