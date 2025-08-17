import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isOnline = true;
  bool _isLoading = false;
  String? _statusMessage;

  // Getters
  int get currentIndex => _currentIndex;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;

  // Constructor
  AppProvider() {
    _checkConnectivity();
  }

  // Bottom navigation index değiştir
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Internet bağlantısını kontrol et
  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      bool wasOnline = _isOnline;
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        _statusMessage =
            'İnternet bağlantısı yeniden kuruldu. Veriler senkronize ediliyor...';
        _syncOfflineData();
      } else if (wasOnline && !_isOnline) {
        _statusMessage =
            'İnternet bağlantısı kesildi. Offline modda çalışıyorsunuz.';
      }

      notifyListeners();
    });
  }

  // Offline verileri senkronize et
  Future<void> _syncOfflineData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Offline verileri Firebase'e sync et
      await Future.delayed(const Duration(seconds: 2)); // Simülasyon

      _statusMessage = 'Veriler başarıyla senkronize edildi.';
    } catch (e) {
      _statusMessage = 'Senkronizasyon hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();

      // Mesajı 3 saniye sonra temizle
      Future.delayed(const Duration(seconds: 3), () {
        _statusMessage = null;
        notifyListeners();
      });
    }
  }

  // Loading durumunu değiştir
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Status mesajı göster
  void showStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();

    // 3 saniye sonra mesajı temizle
    Future.delayed(const Duration(seconds: 3), () {
      if (_statusMessage == message) {
        _statusMessage = null;
        notifyListeners();
      }
    });
  }

  // Status mesajını temizle
  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }
}
