import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage'dan görselleri yüklemek için helper sınıfı
/// Web'de CORS sorunlarını çözmek için signed URL kullanır
class StorageImageHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Firebase Storage URL'sinden signed URL oluşturur (web için)
  /// Mobilde doğrudan URL'yi döndürür
  static Future<String> getImageUrl(String storageUrl) async {
    try {
      // Eğer zaten bir HTTP/HTTPS URL'si ise (mobil için)
      if (storageUrl.startsWith('http://') || storageUrl.startsWith('https://')) {
        // Web'de signed URL oluştur
        if (kIsWeb) {
          // URL'den bucket ve path'i çıkar
          final uri = Uri.parse(storageUrl);
          final path = uri.path;
          
          // Firebase Storage path'ini oluştur
          // Örnek: https://firebasestorage.googleapis.com/v0/b/malzemecim-21.appspot.com/o/products%2F...
          // Path: products/...
          String storagePath = '';
          if (path.contains('/o/')) {
            final parts = path.split('/o/');
            if (parts.length > 1) {
              storagePath = Uri.decodeComponent(parts[1].split('?').first);
            }
          }
          
          if (storagePath.isNotEmpty) {
            try {
              final ref = _storage.ref(storagePath);
              // Signed URL oluştur (1 saat geçerli)
              final url = await ref.getDownloadURL();
              return url;
            } catch (e) {
              debugPrint('Error getting signed URL: $e');
              // Hata durumunda orijinal URL'yi döndür
              return storageUrl;
            }
          }
        }
        return storageUrl;
      }
      
      // Eğer storage path ise
      final ref = _storage.ref(storageUrl);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error in getImageUrl: $e');
      return storageUrl;
    }
  }

  /// Firebase Storage path'inden doğrudan signed URL oluşturur
  static Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      rethrow;
    }
  }
}

