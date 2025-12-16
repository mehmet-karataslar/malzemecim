import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/camera_helper_stub.dart'
    if (dart.library.html) '../../../shared/utils/camera_helper_web.dart'
    if (dart.library.io) '../../../shared/utils/camera_helper_windows.dart' as camera_helper;
import 'dart:io' if (dart.library.html) '../../../shared/utils/platform_stub.dart' as io;
import '../../products/providers/product_provider.dart';
import '../../products/screens/product_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? lastScannedCode;
  bool isScanning = true;
  bool isFlashOn = false;
  final TextEditingController _manualInputController = TextEditingController();
  MobileScannerController? scannerController;
  bool _hasError = false;
  String? _errorMessage;
  bool _isInitializing = true;
  List<camera_helper.CameraDevice> _availableCameras = [];
  camera_helper.CameraDevice? _selectedCamera;
  bool _isFocusing = false;
  bool _permissionRequested = false;
  String? _lastProcessedCode; // Son işlenen barkod
  DateTime? _lastProcessedTime; // Son işlenme zamanı
  bool _isNavigating = false; // Detay sayfasına gidiliyor mu?

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitialize();
  }

  /// Kamera izni iste ve scanner'ı başlat
  Future<void> _requestPermissionAndInitialize() async {
    // İzin durumunu kontrol et
    bool hasPermission = false;

    if (kIsWeb) {
      // Web için kamera izni iste
      hasPermission = await camera_helper.CameraHelper.requestCameraPermission();
      if (!hasPermission) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'Kamera izni verilmedi.\n\nLütfen:\n1. Tarayıcınızın kamera iznini verin\n2. HTTPS veya localhost kullanın\n3. Sayfayı yenileyin';
        });
        _showPermissionDialog();
        return;
      }
    } else {
      // Mobil için permission_handler kullan
      final isWindows = _isWindowsPlatform();
      if (!isWindows) {
        // Android/iOS için izin kontrolü
        final status = await Permission.camera.status;
        
        if (status.isDenied) {
          // İzin henüz istenmemiş, iste
          final result = await Permission.camera.request();
          hasPermission = result.isGranted;
        } else if (status.isPermanentlyDenied) {
          // İzin kalıcı olarak reddedilmiş, ayarlara yönlendir
          setState(() {
            _isInitializing = false;
            _hasError = true;
            _errorMessage = 'Kamera izni kalıcı olarak reddedilmiş.\n\nLütfen uygulama ayarlarından kamera iznini açın.';
          });
          _showPermissionDialog(isPermanentlyDenied: true);
          return;
        } else {
          hasPermission = status.isGranted;
        }

        if (!hasPermission) {
          setState(() {
            _isInitializing = false;
            _hasError = true;
            _errorMessage = 'Kamera izni verilmedi.\n\nLütfen uygulama ayarlarından kamera iznini verin.';
          });
          _showPermissionDialog();
          return;
        }
      }
    }

    // İzin alındıysa scanner'ı başlat
    await _initializeScanner();
  }

  /// Kamera izni dialogu göster
  void _showPermissionDialog({bool isPermanentlyDenied = false}) {
    if (_permissionRequested) return;
    _permissionRequested = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.camera_alt,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Kamera İzni Gerekli'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kIsWeb
                  ? 'Barkod taramak için kamera erişimine ihtiyacımız var.'
                  : 'Barkod taramak için kamera iznine ihtiyacımız var.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (kIsWeb) ...[
              _buildPermissionStep('1', 'Tarayıcı adres çubuğundaki kamera ikonuna tıklayın'),
              _buildPermissionStep('2', 'Kamera iznini "İzin Ver" olarak seçin'),
              _buildPermissionStep('3', 'Sayfayı yenileyin'),
            ] else ...[
              if (isPermanentlyDenied)
                _buildPermissionStep('1', 'Ayarlar > Uygulamalar > malzemecim > İzinler')
              else
                _buildPermissionStep('1', 'Açılan izin penceresinde "İzin Ver" seçeneğini seçin'),
              _buildPermissionStep('2', 'Kamera iznini açın'),
              _buildPermissionStep('3', 'Uygulamayı yeniden başlatın'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _permissionRequested = false;
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          if (isPermanentlyDenied && !kIsWeb)
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                _permissionRequested = false;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ayarlara Git'),
            )
          else
            ElevatedButton(
              onPressed: () async {
                _permissionRequested = false;
                Navigator.pop(context);
                await _requestPermissionAndInitialize();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeScanner() async {
    try {
      // Windows kontrolü (sadece Windows için özel işlem)
    if (!kIsWeb) {
        final isWindows = _isWindowsPlatform();
        if (isWindows) {
          // Windows için özel işlem
          try {
            _availableCameras = await camera_helper.CameraHelper.getAvailableCameras();
            final phoneCameras = await camera_helper.CameraHelper.getPhoneCameras();
            if (phoneCameras.isNotEmpty) {
              _selectedCamera = phoneCameras.first;
              debugPrint('Windows: Telefon kamerası bulundu: ${_selectedCamera!.label}');
            } else if (_availableCameras.isNotEmpty) {
              _selectedCamera = _availableCameras.first;
              debugPrint('Windows: Kamera bulundu: ${_selectedCamera!.label}');
            }
            
            setState(() {
              _isInitializing = false;
              _hasError = false;
            });
          } catch (e) {
            debugPrint('Windows kamera hatası: $e');
            setState(() {
              _isInitializing = false;
              _hasError = false;
            });
          }
          return; // Windows için burada çık
        }
        // Mobil platformlar (Android/iOS) için devam et
      }

      // Web ve mobil (Android/iOS) için scanner controller oluştur
      scannerController = MobileScannerController(
        detectionSpeed: kIsWeb ? DetectionSpeed.normal : DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        autoStart: true,
        formats: [
          BarcodeFormat.qrCode,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.codabar,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.itf,
        ],
      );

      // Controller'ın başlatılmasını bekle
      await Future.delayed(Duration(milliseconds: kIsWeb ? 2000 : 1500));

      // Web için kamera listesini al (mobilde mobile_scanner kendi yönetir)
      if (kIsWeb) {
        try {
          _availableCameras = await camera_helper.CameraHelper.getAvailableCameras();
          if (_availableCameras.isNotEmpty) {
            _selectedCamera = _availableCameras.first;
          }
        } catch (e) {
          debugPrint('Kamera listesi alınamadı: $e');
        }
      }

      // Odaklanma için kısa bir delay
      if (scannerController != null) {
        _triggerFocus();
      }

      setState(() {
        _isInitializing = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        final isWindows = !kIsWeb && _isWindowsPlatform();
        _errorMessage = 'Kamera başlatılamadı: $e\n\nLütfen:\n${kIsWeb ? '1. Tarayıcı ayarlarından kamera iznini verin\n2. HTTPS veya localhost kullanın\n' : isWindows ? '1. Windows Ayarlar > Gizlilik > Kamera\'dan izin verin\n2. Başka bir uygulama kamerayı kullanmıyorsa kontrol edin\n' : '1. Uygulama ayarlarından kamera iznini verin\n2. Cihazınızın kamerasının çalıştığından emin olun\n'}3. Uygulamayı yeniden başlatın';
      });
    }
  }

  /// Platform kontrolü (Web'de false döner)
  bool _isWindowsPlatform() {
    if (kIsWeb) return false;
    try {
      return io.Platform.isWindows;
    } catch (e) {
      return false;
    }
  }

  /// Odaklanmayı tetikle
  void _triggerFocus() {
    if (scannerController == null || _isFocusing) return;
    
    setState(() {
      _isFocusing = true;
    });

    // Web için daha sık odaklanma tetikle
    if (kIsWeb) {
      // Web'de periyodik olarak odaklanmayı tetikle
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && scannerController != null) {
          // Web'de manuel odaklanma için tekrar tetikle
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _isFocusing = false;
              });
            }
          });
        }
      });
    } else {
      // Mobil için normal odaklanma
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isFocusing = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Barkod Tarayıcı'),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          // Web ve Windows için kamera seçimi
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && _availableCameras.length > 1)
            _buildActionButton(
              icon: Icons.videocam,
              onPressed: _showCameraSelector,
              tooltip: 'Kamera Seç',
            ),
          // Web ve Windows için kamera değiştirme
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && scannerController != null)
            _buildActionButton(
              icon: Icons.cameraswitch,
              onPressed: () {
                scannerController?.switchCamera();
              },
              tooltip: 'Kamera Değiştir',
            ),
          // Odaklanma butonu
          if (scannerController != null)
            _buildActionButton(
              icon: Icons.center_focus_strong,
              onPressed: _triggerFocus,
              tooltip: 'Odaklan',
            ),
          _buildActionButton(
            icon: isScanning ? Icons.pause : Icons.play_arrow,
            onPressed: _toggleScanning,
            tooltip: isScanning ? 'Duraklat' : 'Başlat',
          ),
          // Web'de flash desteklenmiyor
          if (!kIsWeb)
            _buildActionButton(
              icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
            onPressed: _toggleFlash,
              tooltip: 'Flaş',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
              if (isMobile) {
          return Column(
            children: [
                    // Scanner Area - Mobilde daha fazla alan
                    Expanded(flex: 5, child: _buildScannerArea()),
                    // Info Panel - Mobilde daha kompakt
                    Expanded(flex: 2, child: _buildInfoPanel(authProvider)),
                  ],
                );
              } else {
                return Row(
                  children: [
                    // Scanner Area - Web'de yan yana
                    Expanded(flex: 3, child: _buildScannerArea()),
                    // Info Panel - Web'de yan panel
                    Expanded(flex: 2, child: _buildInfoPanel(authProvider)),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: Colors.white,
      ),
    );
  }

  Widget _buildScannerArea() {
    // Hata durumu
    if (_hasError) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.errorColor, width: 2),
          color: Colors.red[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Kamera Hatası',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Kamera erişimi sağlanamadı',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    // Yükleniyor durumu
    if (_isInitializing) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Kamera başlatılıyor...'),
            ],
          ),
        ),
      );
    }

    // Windows'ta kamera listesi göster (Web değilse)
    if (!kIsWeb && _isWindowsPlatform()) {
      if (_availableCameras.isEmpty) {
        // Kamera yok, manuel giriş göster
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor, width: 2),
            color: Colors.blue[50],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 60, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Kamera Bulunamadı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'USB ile telefon bağladıysanız:\n1. Telefonunuzda "USB Debugging" veya "File Transfer" modunu açın\n2. Windows Ayarlar > Gizlilik > Kamera\'dan izin verin\n3. Sayfayı yenileyin',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                  setState(() {
                      _isInitializing = true;
                  });
                    await _initializeScanner();
              },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kamerayı Yeniden Tara'),
            ),
                const SizedBox(height: 12),
                _buildWindowsAlternatives(),
          ],
            ),
        ),
      );
    } else {
        // Kamera var, listele
      return Container(
        margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
            color: Colors.green[50],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 60, color: Colors.green[700]),
              const SizedBox(height: 12),
              Text(
                '${_availableCameras.length} Kamera Bulundu!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableCameras.length,
                  itemBuilder: (context, index) {
                    final camera = _availableCameras[index];
                    final isSelected = _selectedCamera?.deviceId == camera.deviceId;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? Colors.green[100] : null,
                      child: ListTile(
                        leading: Icon(
                          camera.isPhoneCamera 
                            ? Icons.phone_android 
                            : camera.isUsbCamera 
                              ? Icons.usb 
                              : Icons.videocam,
                          color: isSelected ? AppTheme.primaryColor : null,
                        ),
                        title: Text(
                          camera.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          camera.isPhoneCamera 
                            ? '📱 Telefon Kamerası' 
                            : camera.isUsbCamera 
                              ? '🔌 USB Kamera' 
                              : '📷 Yerleşik Kamera',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check, color: Colors.green, size: 20)
                          : null,
                        dense: true,
                        onTap: () {
                          setState(() {
                            _selectedCamera = camera;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${camera.label} seçildi'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '💡 Windows\'ta kamera tarayıcı için web versiyonunu kullanabilirsiniz.\nBurada sadece manuel giriş ve USB barkod okuyucu kullanılabilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Web ve mobil için aynı kamera tarayıcı kullan
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : (kIsWeb ? 24 : 16)),
      constraints: kIsWeb 
        ? const BoxConstraints(maxWidth: 1200, maxHeight: 800)
        : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        border: Border.all(
          color: AppTheme.primaryColor, 
          width: isMobile ? 3 : 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: isMobile ? 15 : 25,
            spreadRadius: isMobile ? 2 : 4,
            offset: const Offset(0, 4),
          ),
        ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
        child: Stack(
          children: [
            if (scannerController != null)
              AspectRatio(
                aspectRatio: kIsWeb ? 16 / 9 : (isMobile ? 3 / 4 : 4 / 3),
                child: MobileScanner(
                  controller: scannerController!,
                  onDetect: (BarcodeCapture capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && isScanning && !_isNavigating) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty) {
                        // Aynı barkodun tekrar algılanmasını engelle
                        final now = DateTime.now();
                        if (_lastProcessedCode == code && 
                            _lastProcessedTime != null &&
                            now.difference(_lastProcessedTime!) < const Duration(seconds: 3)) {
                          return; // Aynı barkod, yok say
                        }

                        // Yeni barkod algılandı
                        _lastProcessedCode = code;
                        _lastProcessedTime = now;
                        
                        setState(() {
                          lastScannedCode = code;
                          isScanning = false;
                          _isNavigating = true;
                        });
                        
                        // Scanner'ı durdur
                        scannerController?.stop();
                        
                        // Otomatik olarak ürün detay sayfasına git
                        _searchProductAndNavigate(code);
                      }
                    }
                  },
                  fit: kIsWeb ? BoxFit.contain : BoxFit.cover,
                  errorBuilder: (context, error, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey[100]!,
                            Colors.grey[200]!,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: isMobile ? 48 : 64,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Kamera erişimi gerekli',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 32),
                              child: Text(
                                kIsWeb
                                    ? 'Lütfen tarayıcınızın kamera iznini verin\n(HTTPS veya localhost gerekli)'
                                    : 'Lütfen uygulama ayarlarından kamera iznini verin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _initializeScanner,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Modern scanning overlay
            _buildModernScanningOverlay(),

            // Odaklanma göstergesi
            if (_isFocusing)
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Container(
                      width: 100 * value,
                      height: 100 * value,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(1 - value),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    );
                  },
                ),
              ),

            // Web ve Windows için kamera bilgisi
            if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && _selectedCamera != null)
              Positioned(
                top: isMobile ? 12 : 16,
                left: isMobile ? 12 : 16,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 12,
                    vertical: isMobile ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCamera!.isUsbCamera 
                          ? Icons.usb 
                          : _selectedCamera!.isPhoneCamera 
                            ? Icons.phone_android 
                            : Icons.videocam,
                        size: isMobile ? 14 : 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCamera!.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernScanningOverlay() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final scanFrameWidth = isMobile ? 250.0 : 300.0;
    final scanFrameHeight = isMobile ? 120.0 : 150.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Stack(
        children: [
          // Köşeleri kesilmiş tarama çerçevesi
          Center(
            child: Container(
              width: scanFrameWidth,
              height: scanFrameHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Animasyonlu köşe göstergeleri
                  ...List.generate(4, (index) {
                    return Positioned(
                      top: index < 2 ? -2 : null,
                      bottom: index >= 2 ? -2 : null,
                      left: index % 2 == 0 ? -2 : null,
                      right: index % 2 == 1 ? -2 : null,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.3 + (value * 0.7)),
                              borderRadius: BorderRadius.only(
                                topLeft: index == 0
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                topRight: index == 1
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomLeft: index == 2
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                                bottomRight: index == 3
                                    ? const Radius.circular(12)
                                    : Radius.zero,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Tarama talimatları
          Positioned(
            bottom: isMobile ? 30 : 40,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    color: Colors.white,
                    size: isMobile ? 18 : 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      lastScannedCode != null
                          ? 'Barkod algılandı!'
                          : 'Barkodu çerçeve içine yerleştirin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kamera seçim dialogu göster
  void _showCameraSelector() {
    if (_availableCameras.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kamera Seç'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableCameras.length,
            itemBuilder: (context, index) {
              final camera = _availableCameras[index];
              final isSelected = _selectedCamera?.deviceId == camera.deviceId;
              
              return ListTile(
                leading: Icon(
                  camera.isUsbCamera 
                    ? Icons.usb 
                    : camera.isPhoneCamera 
                      ? Icons.phone_android 
                      : Icons.videocam,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
                title: Text(camera.label),
                subtitle: Text(
                  camera.isUsbCamera 
                    ? 'USB Kamera' 
                    : camera.isPhoneCamera 
                      ? 'Telefon Kamerası' 
                      : 'Yerleşik Kamera',
                ),
                trailing: isSelected 
                  ? Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
                onTap: () {
                  _selectCamera(camera);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  /// Kamera seç
  Future<void> _selectCamera(camera_helper.CameraDevice camera) async {
    if (_selectedCamera?.deviceId == camera.deviceId) return;

    setState(() {
      _selectedCamera = camera;
      _isInitializing = true;
    });

    // Eski controller'ı kapat
    await scannerController?.stop();
    await scannerController?.dispose();

      // Yeni controller oluştur (Web için optimize)
      try {
        scannerController = MobileScannerController(
          detectionSpeed: kIsWeb ? DetectionSpeed.normal : DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          torchEnabled: false,
          returnImage: false,
          autoStart: true,
          formats: [
            BarcodeFormat.qrCode,
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.code128,
            BarcodeFormat.code39,
            BarcodeFormat.code93,
            BarcodeFormat.codabar,
            BarcodeFormat.dataMatrix,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.itf,
          ],
        );

      await Future.delayed(const Duration(milliseconds: 500));
      _triggerFocus();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = 'Kamera seçilemedi: $e';
      });
    }
  }

  Widget _buildInfoPanel(AuthProvider authProvider) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMobile ? 24 : 0),
          topRight: Radius.circular(isMobile ? 24 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
          Text(
            'Tarama Durumu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // İçerik
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Scan Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 14 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isScanning
                            ? [
                                AppTheme.successColor.withOpacity(0.1),
                                AppTheme.successColor.withOpacity(0.05),
                              ]
                            : [
                                AppTheme.warningColor.withOpacity(0.1),
                                AppTheme.warningColor.withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isScanning
                            ? AppTheme.successColor.withOpacity(0.3)
                            : AppTheme.warningColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                color: isScanning
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isScanning ? Icons.qr_code_scanner : Icons.pause_circle,
                            color: Colors.white,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
              Text(
                                isScanning ? 'Tarama Aktif' : 'Tarama Duraklatıldı',
                style: TextStyle(
                  color: isScanning
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isScanning
                                    ? 'Barkod algılanıyor...'
                                    : 'Tarama durduruldu',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ],
                          ),
                        ),
                      ],
                    ),
          ),

          const SizedBox(height: 16),

          // Last Scanned Code
          if (lastScannedCode != null) ...[
            Text(
                      'Son Taranan Kod',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: AppTheme.primaryColor,
                            size: isMobile ? 20 : 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
              child: Text(
                lastScannedCode!,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _searchProductAndNavigate(lastScannedCode!),
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(isMobile ? 'Ara' : 'Ürün Ara'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (authProvider.isAdmin) ...[
                          const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addNewProduct(lastScannedCode!),
                              icon: const Icon(Icons.add, size: 20),
                              label: Text(isMobile ? 'Ekle' : 'Yeni Ürün'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 14 : 16,
                                ),
                                side: const BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
              ],
            ),
          ] else ...[
            // No scan yet
            Container(
              width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 2,
                        ),
              ),
              child: Column(
                children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.qr_code_2,
                              size: isMobile ? 40 : 48,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                  Text(
                    'Barkod veya QR kodu taramak için\nkamerayı ürün üzerine tutun',
                    textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                ],
              ),
            ),
          ],

          // Quick Actions (Admin only)
          if (authProvider.isAdmin && lastScannedCode != null) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
            const SizedBox(height: 16),
            Text(
              'Hızlı İşlemler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
            ),
                    ),
                    const SizedBox(height: 12),
            _buildQuickActions(),
          ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildQuickActionChip(
          icon: Icons.calculate,
          label: 'Fiyat Hesapla',
          onTap: _showPriceCalculator,
        ),
        _buildQuickActionChip(
          icon: Icons.inventory_2,
          label: 'Stok Güncelle',
          onTap: _showStockUpdate,
        ),
        _buildQuickActionChip(
          icon: Icons.account_balance_wallet,
          label: 'Veresiye Ekle',
          onTap: _showCreditAdd,
        ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 16 : 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Taramayı sıfırla ve tekrar başlat
  void _resetScanning() {
    setState(() {
      isScanning = true;
      lastScannedCode = null;
      _isNavigating = false;
      _lastProcessedCode = null;
      _lastProcessedTime = null;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && scannerController != null) {
        scannerController?.start();
      }
    });
  }

  void _toggleScanning() {
    setState(() {
      isScanning = !isScanning;
      if (!isScanning) {
        // Tarama durdurulduğunda flag'leri temizle
        _lastProcessedCode = null;
        _lastProcessedTime = null;
        _isNavigating = false;
      }
    });
    
    if (scannerController != null) {
      if (isScanning) {
        scannerController!.start();
      } else {
        scannerController!.stop();
      }
    }
  }

  void _toggleFlash() {
    // Web'de flash özelliği yok
    if (kIsWeb || scannerController == null) return;

    setState(() {
      isFlashOn = !isFlashOn;
    });

    scannerController!.toggleTorch();
  }

  /// Barkod ile ürün ara ve otomatik olarak detay sayfasına yönlendir
  void _searchProductAndNavigate(String code) async {
    // Eğer zaten navigasyon yapılıyorsa, tekrar işlem yapma
    if (_isNavigating) return;
    
    // Ürünleri yükle (eğer yüklenmemişse)
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.products.isEmpty) {
      await productProvider.loadProducts();
    }

    // Barkod ile ürün ara
    final product = productProvider.getProductByBarcode(code);

    if (product != null) {
      // Ürün bulundu - direkt detay sayfasına git
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        ).then((_) {
          // Geri dönüldüğünde taramayı tekrar başlat
          if (mounted) {
            _resetScanning();
          }
        });

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Ürün bulundu: ${product.name}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Ürün bulunamadı - navigasyon flag'ini sıfırla
      setState(() {
        _isNavigating = false;
      });
      
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Ürün Bulunamadı'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barkod: $code',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bu barkod ile eşleşen bir ürün bulunamadı.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Taramayı tekrar başlat
                  _resetScanning();
                },
                child: const Text('Tamam'),
              ),
              if (authProvider.isAdmin)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Yeni ürün ekleme sayfasına yönlendir
                    Navigator.pushNamed(
                      context,
                      '/add-product',
                      arguments: {'barcode': code},
                    ).then((_) {
                      // Geri dönüldüğünde taramayı tekrar başlat
                      if (mounted) {
                        _resetScanning();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Yeni Ürün Ekle'),
                ),
            ],
          ),
        );
      }
    }
  }

  /// Eski metod - geriye uyumluluk için
  void _searchProduct(String code) {
    _searchProductAndNavigate(code);
  }

  void _addNewProduct(String code) {
    // Yeni ürün ekleme sayfasına barkod ile yönlendir
    Navigator.pushNamed(context, '/add-product', arguments: {'barcode': code});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barkod ile ürün ekleme: $code'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showPriceCalculator() {
    // TODO: Fiyat hesaplama dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fiyat Hesaplama'),
        content: const Text('KDV ve iskonto hesaplama özelliği yakında...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showStockUpdate() {
    // TODO: Stok güncelleme dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Güncelleme'),
        content: const Text('Stok güncelleme özelliği yakında...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showCreditAdd() {
    // TODO: Veresiye ekleme dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veresiye Ekleme'),
        content: const Text('Veresiye ekleme özelliği yakında...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsAlternatives() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Manuel giriş
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.keyboard, color: AppTheme.primaryColor, size: 20),
            title: const Text('Manuel Barkod Girişi', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Barkodu klavyeden girin', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            dense: true,
            onTap: () {
              _showManualInputDialog();
            },
          ),
        ),
        const SizedBox(height: 8),
        // USB Barkod Okuyucu
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.usb, color: AppTheme.primaryColor, size: 20),
            title: const Text('USB Barkod Okuyucu', style: TextStyle(fontSize: 14)),
            subtitle: const Text('USB barkod okuyucu bağlayın ve tarayın', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            dense: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('USB barkod okuyucu bağlayın ve barkodu tarayın. Sistem otomatik algılayacaktır.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Web versiyonu kullan
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.web, color: AppTheme.primaryColor, size: 20),
            title: const Text('Web Versiyonunu Kullan', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Tarayıcıda açarak kamera kullanabilirsiniz', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            dense: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Web versiyonunda kamera tarayıcı çalışmaktadır.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manuel Barkod Girişi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Barkod',
            hintText: 'Barkod numarasını girin',
            prefixIcon: Icon(Icons.qr_code),
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              _searchProductAndNavigate(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _searchProductAndNavigate(controller.text);
              }
            },
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }
}
