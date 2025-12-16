import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../utils/camera_helper_stub.dart'
    if (dart.library.html) '../utils/camera_helper_web.dart'
    if (dart.library.io) '../utils/camera_helper_windows.dart' as camera_helper;
import 'dart:io' if (dart.library.html) '../utils/platform_stub.dart' as io;

class BarcodeScannorPage extends StatefulWidget {
  const BarcodeScannorPage({super.key});

  @override
  State<BarcodeScannorPage> createState() => _BarcodeScannorPageState();
}

class _BarcodeScannorPageState extends State<BarcodeScannorPage> {
  MobileScannerController? scannerController;
  bool isFlashOn = false;
  String? detectedCode;
  final TextEditingController _manualInputController = TextEditingController();
  bool _hasError = false;
  String? _errorMessage;
  bool _isInitializing = true;
  List<camera_helper.CameraDevice> _availableCameras = [];
  camera_helper.CameraDevice? _selectedCamera;
  bool _isFocusing = false;
  double _zoomLevel = 1.0;
  bool _permissionRequested = false;

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
            const Text('Barkod Tara'),
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
          // Web ve Windows için kamera değiştirme butonu
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && scannerController != null)
            _buildActionButton(
              icon: Icons.cameraswitch,
              onPressed: _switchCamera,
              tooltip: 'Kamera Değiştir',
            ),
          // Odaklanma butonu
          if (scannerController != null)
            _buildActionButton(
              icon: Icons.center_focus_strong,
              onPressed: _triggerFocus,
              tooltip: 'Odaklan',
            ),
          // Web'de flash desteklenmiyor, sadece mobilde göster
          if (!kIsWeb && scannerController != null)
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
          child: Column(
            children: [
              // Scanner Area
              Expanded(flex: isMobile ? 4 : 3, child: _buildScannerArea()),

              // Manual Input & Controls
              Expanded(flex: isMobile ? 1 : 1, child: _buildControlsArea()),
            ],
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

    // Yeni controller oluştur
    try {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
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

  Widget _buildScannerArea() {
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
            const SizedBox(height: 16),
            // Manuel giriş alternatifi
            OutlinedButton.icon(
              onPressed: () {
                // Manuel giriş alanına odaklan
                FocusScope.of(context).requestFocus(
                  FocusNode()..requestFocus(),
                );
              },
              icon: const Icon(Icons.keyboard),
              label: const Text('Manuel Giriş Kullan'),
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
          border: Border.all(color: AppTheme.primaryColor, width: 3),
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
                  onDetect: _onBarcodeDetect,
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
            _buildScanningOverlay(),

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

  Widget _buildScanningOverlay() {
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
                      detectedCode != null
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

  Widget _buildControlsArea() {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manuel giriş alanı
          TextField(
            controller: _manualInputController,
            decoration: InputDecoration(
              labelText: 'Manuel Barkod Girişi',
              hintText: '1234567890123',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: AppTheme.primaryColor,
                  size: isMobile ? 20 : 24,
                ),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _submitManualCode,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
            ),
            style: TextStyle(fontSize: isMobile ? 14 : 16),
            onSubmitted: (_) => _submitManualCode(),
          ),

          SizedBox(height: isMobile ? 12 : 16),

          // Butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('İptal'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 14 : 16,
                    ),
                    side: BorderSide(
                      color: Colors.grey[400]!,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (detectedCode != null) ...[
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, detectedCode),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Kullan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty && code != detectedCode) {
        // En az 3 karakter olması gerekiyor
        if (code.length < 3) return;

        setState(() {
          detectedCode = code;
        });

        // Ses/titreşim feedback'i
        try {
          // HapticFeedback.mediumImpact();
        } catch (e) {
          // Platform desteklemiyorsa sessizce devam et
        }

        // Başarılı algılama bildirimi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barkod algılandı: $code'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
          ),
        );

        // 2 saniye sonra otomatik onaylama (kullanıcı isterse daha önce onaylayabilir)
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted && detectedCode == code) {
            Navigator.pop(context, code);
          }
        });
      }
    }
  }

  void _submitManualCode() {
    final code = _manualInputController.text.trim();
    if (code.isNotEmpty) {
      Navigator.pop(context, code);
    }
  }

  void _toggleFlash() {
    if (kIsWeb || scannerController == null) return;

    setState(() {
      isFlashOn = !isFlashOn;
    });

    scannerController!.toggleTorch();
  }

  void _switchCamera() {
    if (scannerController == null) return;
    
    // Web'de kamera değiştirme
    scannerController!.switchCamera();
  }
}
