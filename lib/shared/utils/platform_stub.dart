/// Stub for Platform class when running on web
/// Web'de dart:io kullanılamaz, bu stub kullanılır
class Platform {
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

