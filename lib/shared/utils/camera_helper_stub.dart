import 'package:flutter/foundation.dart';

/// Stub implementation for non-web platforms
class CameraHelper {
  static Future<List<CameraDevice>> getAvailableCameras() async {
    return [];
  }

  static Future<bool> requestCameraPermission() async {
    return true;
  }

  static Future<dynamic> getCameraStream(String deviceId) async {
    return null;
  }

  static Future<List<CameraDevice>> getUsbCameras() async {
    return [];
  }

  static Future<List<CameraDevice>> getPhoneCameras() async {
    return [];
  }
}

class CameraDevice {
  final String deviceId;
  final String label;
  final String groupId;

  CameraDevice({
    required this.deviceId,
    required this.label,
    required this.groupId,
  });

  bool get isUsbCamera => false;
  bool get isPhoneCamera => false;

  @override
  String toString() => label;
}

