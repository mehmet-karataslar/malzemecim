class AppConstants {
  // App Info
  static const String appName = 'Malzemecim';
  static const String appVersion = '1.0.0';

  // Colors (Teknik raporda belirtilen tema)
  static const String primaryColorHex = '#1e3a8a'; // Koyu mavi
  static const String backgroundColorHex = '#ffffff'; // Beyaz

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String inventoryCollection = 'inventory';
  static const String creditCollection = 'credit';
  static const String reportsCollection = 'reports';
  static const String notesCollection = 'notes';
  static const String appointmentsCollection = 'appointments';

  // User Roles
  static const String adminRole = 'admin';
  static const String employeeRole = 'employee';

  // Product Units
  static const List<String> productUnits = [
    'adet',
    'kg',
    'litre',
    'metre',
    'm²',
    'm³',
  ];

  // Settings
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String userRoleKey = 'user_role';
  static const String offlineModeKey = 'offline_mode';

  // Performance
  static const int maxProductsPerPage = 50;
  static const int barcodeReadTimeout = 1000; // ms
  static const int syncTimeout = 30000; // ms
}
