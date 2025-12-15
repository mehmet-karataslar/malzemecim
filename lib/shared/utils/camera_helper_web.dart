import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web implementation for camera helper
class CameraHelper {
  /// Mevcut kameraları listeler (Web için)
  /// Not: mobile_scanner zaten kamera açtığı için label'lar dolu olmalı
  static Future<List<CameraDevice>> getAvailableCameras() async {
    try {
      // mobile_scanner zaten kamera açtığı için label'lar dolu olmalı
      // getUserMedia çağrısı yapmaya gerek yok
      final devices = await html.window.navigator.mediaDevices?.enumerateDevices();
      if (devices == null) return [];

      final cameras = <CameraDevice>[];
      
      for (var device in devices) {
        if (device.kind == 'videoinput') {
          cameras.add(CameraDevice(
            deviceId: device.deviceId ?? '',
            label: device.label.isNotEmpty 
                ? device.label 
                : 'Kamera ${cameras.length + 1}',
            groupId: device.groupId ?? '',
          ));
        }
      }

      return cameras;
    } catch (e) {
      debugPrint('Kamera listesi alınamadı: $e');
      return [];
    }
  }

  /// Kamera izni ister (yüksek kalite constraints ile)
  static Future<bool> requestCameraPermission() async {
    try {
      // Sadece MediaDevices API'nin varlığını kontrol et
      // Gerçek izin kontrolünü mobile_scanner yapacak
      if (html.window.navigator.mediaDevices == null) {
        return false;
      }
      
      // Yüksek kalite constraints ile test et
      try {
        final stream = await html.window.navigator.mediaDevices?.getUserMedia({
          'video': {
            'width': {'ideal': 1920},
            'height': {'ideal': 1080},
            'facingMode': 'environment',
          },
        });
        stream?.getTracks().forEach((track) => track.stop());
        return stream != null;
      } catch (e) {
        // Yüksek kalite başarısız olursa normal kalite dene
        try {
          final stream = await html.window.navigator.mediaDevices?.getUserMedia({
            'video': true,
          });
          stream?.getTracks().forEach((track) => track.stop());
          return stream != null;
        } catch (e2) {
          debugPrint('Kamera izni alınamadı: $e2');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Kamera API kontrolü başarısız: $e');
      return false;
    }
  }

  /// Belirli bir kamera ID'si ile stream alır
  static Future<html.MediaStream?> getCameraStream(String deviceId) async {
    try {
      return await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'deviceId': {'exact': deviceId},
        },
      });
    } catch (e) {
      debugPrint('Kamera stream alınamadı: $e');
      return null;
    }
  }

  /// USB cihaz algılama (videoinput cihazları)
  static Future<List<CameraDevice>> getUsbCameras() async {
    final allCameras = await getAvailableCameras();
    
    // USB kameraları genelde label'larında "USB" veya "Webcam" içerir
    return allCameras.where((camera) {
      final label = camera.label.toLowerCase();
      return label.contains('usb') || 
             label.contains('webcam') ||
             label.contains('camera') ||
             label.contains('video');
    }).toList();
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

  CameraDevice({
    required this.deviceId,
    required this.label,
    required this.groupId,
  });

  bool get isUsbCamera {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('usb') || 
           lowerLabel.contains('webcam');
  }

  bool get isPhoneCamera {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('phone') || 
           lowerLabel.contains('mobile') ||
           lowerLabel.contains('android') ||
           lowerLabel.contains('iphone');
  }

  @override
  String toString() => label;
}

