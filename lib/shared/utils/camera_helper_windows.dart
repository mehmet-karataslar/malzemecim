import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:camera/camera.dart';

/// Windows desktop için kamera yardımcı sınıfı
/// camera paketi kullanarak USB bağlı telefonlar dahil tüm kameraları algılar
class CameraHelper {
  /// Mevcut kameraları listeler (Windows için)
  /// USB bağlı telefonlar dahil tüm kameraları algılar
  static Future<List<CameraDevice>> getAvailableCameras() async {
    try {
      // camera paketi ile tüm kameraları al
      final cameras = await availableCameras();
      
      final cameraDevices = <CameraDevice>[];
      
      for (int index = 0; index < cameras.length; index++) {
        final camera = cameras[index];
        // Kamera bilgilerini al
        final label = _getCameraLabel(camera);
        
        cameraDevices.add(CameraDevice(
          deviceId: index.toString(), // Index'i ID olarak kullan
          label: label,
          groupId: camera.lensDirection.toString(),
          cameraDescription: camera, // CameraDescription'ı sakla
        ));
      }

      debugPrint('Windows: ${cameras.length} kamera bulundu');
      return cameraDevices;
    } catch (e) {
      debugPrint('Windows kamera listesi alınamadı: $e');
      return [];
    }
  }

  /// Kamera etiketini oluştur
  static String _getCameraLabel(CameraDescription camera) {
    final name = camera.name.toLowerCase();
    
    // Telefon kamerası kontrolü
    if (name.contains('phone') || 
        name.contains('mobile') ||
        name.contains('android') ||
        name.contains('iphone') ||
        name.contains('samsung') ||
        name.contains('huawei') ||
        name.contains('xiaomi') ||
        name.contains('oppo') ||
        name.contains('vivo') ||
        name.contains('oneplus') ||
        name.contains('realme')) {
      return '📱 ${camera.name} (Telefon Kamerası)';
    }
    
    // USB kamera kontrolü
    if (name.contains('usb') || 
        name.contains('webcam') ||
        name.contains('external')) {
      return '🔌 ${camera.name} (USB Kamera)';
    }
    
    // Yerleşik kamera
    return '📷 ${camera.name}';
  }

  /// USB kamera kontrolü
  static bool _isUsbCamera(CameraDescription camera) {
    final name = camera.name.toLowerCase();
    return name.contains('usb') || 
           name.contains('webcam') ||
           name.contains('external');
  }

  /// Telefon kamerası kontrolü
  static bool _isPhoneCamera(CameraDescription camera, String label) {
    final name = camera.name.toLowerCase();
    final lowerLabel = label.toLowerCase();
    
    return name.contains('phone') || 
           name.contains('mobile') ||
           name.contains('android') ||
           name.contains('iphone') ||
           name.contains('samsung') ||
           name.contains('huawei') ||
           name.contains('xiaomi') ||
           name.contains('oppo') ||
           name.contains('vivo') ||
           name.contains('oneplus') ||
           name.contains('realme') ||
           lowerLabel.contains('telefon') ||
           lowerLabel.contains('phone');
  }

  /// Kamera izni kontrolü (Windows için)
  /// Windows'ta izin Windows ayarlarından kontrol edilir
  static Future<bool> requestCameraPermission() async {
    try {
      // camera paketi ile izin kontrolü
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      debugPrint('Windows kamera izni kontrolü başarısız: $e');
      return false;
    }
  }

  /// Belirli bir kamera ID'si ile CameraDescription alır
  static Future<CameraDescription?> getCameraById(String deviceId) async {
    try {
      final cameras = await availableCameras();
      final cameraId = int.tryParse(deviceId);
      if (cameraId == null) return null;
      
      if (cameraId < cameras.length) {
        return cameras[cameraId];
      }
      return null;
    } catch (e) {
      debugPrint('Windows kamera bulunamadı: $e');
      return null;
    }
  }

  /// USB cihaz algılama (Windows için)
  static Future<List<CameraDevice>> getUsbCameras() async {
    final allCameras = await getAvailableCameras();
    return allCameras.where((camera) => camera.isUsbCamera || camera.isPhoneCamera).toList();
  }

  /// Telefon kameralarını listele
  static Future<List<CameraDevice>> getPhoneCameras() async {
    final allCameras = await getAvailableCameras();
    return allCameras.where((camera) => camera.isPhoneCamera).toList();
  }
}

/// Kamera cihazı modeli
class CameraDevice {
  final String deviceId;
  final String label;
  final String groupId;
  final CameraDescription? cameraDescription; // Windows için CameraDescription

  CameraDevice({
    required this.deviceId,
    required this.label,
    required this.groupId,
    this.cameraDescription,
  });

  bool get isUsbCamera {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('usb') || 
           lowerLabel.contains('webcam') ||
           lowerLabel.contains('external') ||
           lowerLabel.contains('🔌');
  }

  bool get isPhoneCamera {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('phone') || 
           lowerLabel.contains('mobile') ||
           lowerLabel.contains('android') ||
           lowerLabel.contains('iphone') ||
           lowerLabel.contains('telefon') ||
           lowerLabel.contains('📱') ||
           lowerLabel.contains('samsung') ||
           lowerLabel.contains('huawei') ||
           lowerLabel.contains('xiaomi');
  }

  @override
  String toString() => label;
}

