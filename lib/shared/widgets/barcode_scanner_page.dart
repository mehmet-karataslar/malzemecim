import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeScanner();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Tara'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Web ve Windows için kamera seçimi
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && _availableCameras.length > 1)
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: _showCameraSelector,
              tooltip: 'Kamera Seç',
            ),
          // Web ve Windows için kamera değiştirme butonu
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && scannerController != null)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: _switchCamera,
              tooltip: 'Kamera Değiştir',
            ),
          // Odaklanma butonu
          if (scannerController != null)
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _triggerFocus,
              tooltip: 'Odaklan',
            ),
          // Web'de flash desteklenmiyor, sadece mobilde göster
          if (!kIsWeb && scannerController != null)
            IconButton(
              icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
              tooltip: 'Flaş',
            ),
        ],
      ),
      body: Column(
        children: [
          // Scanner Area
          Expanded(flex: 3, child: _buildScannerArea()),

          // Manual Input & Controls
          Expanded(flex: 1, child: _buildControlsArea()),
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
    return Container(
      margin: EdgeInsets.all(kIsWeb ? 24 : 16),
      constraints: kIsWeb 
        ? const BoxConstraints(maxWidth: 1200, maxHeight: 800)
        : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
        border: Border.all(
          color: AppTheme.primaryColor, 
          width: kIsWeb ? 4 : 3,
        ),
        boxShadow: kIsWeb ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 13),
        child: Stack(
          children: [
            if (scannerController != null)
              AspectRatio(
                aspectRatio: kIsWeb ? 16 / 9 : 4 / 3,
                child: MobileScanner(
                  controller: scannerController!,
                  onDetect: _onBarcodeDetect,
                  fit: kIsWeb ? BoxFit.contain : BoxFit.cover, // Web için contain - daha net görüntü
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Kamera erişimi gerekli',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              kIsWeb
                                ? 'Lütfen tarayıcınızın kamera iznini verin\n(HTTPS veya localhost gerekli)'
                                : 'Lütfen uygulama ayarlarından kamera iznini verin',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
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
                  },
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            // Odaklanma göstergesi
            if (_isFocusing)
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),

            // Scanning overlay
            _buildScanningOverlay(),

            // Web ve Windows için kamera bilgisi
            if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && _selectedCamera != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
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
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCamera!.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(13)),
      child: Stack(
        children: [
          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  ...List.generate(4, (index) {
                    return Positioned(
                      top: index < 2 ? 0 : null,
                      bottom: index >= 2 ? 0 : null,
                      left: index % 2 == 0 ? 0 : null,
                      right: index % 2 == 1 ? 0 : null,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: index == 0
                                ? const Radius.circular(8)
                                : Radius.zero,
                            topRight: index == 1
                                ? const Radius.circular(8)
                                : Radius.zero,
                            bottomLeft: index == 2
                                ? const Radius.circular(8)
                                : Radius.zero,
                            bottomRight: index == 3
                                ? const Radius.circular(8)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detectedCode != null
                    ? 'Barkod algılandı: $detectedCode'
                    : 'Barkodu çerçeve içine yerleştirin',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Manuel giriş alanı
          TextField(
            controller: _manualInputController,
            decoration: InputDecoration(
              labelText: 'Manuel Barkod Girişi',
              hintText: '1234567890123',
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _submitManualCode,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _submitManualCode(),
          ),

          const SizedBox(height: 16),

          // Butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('İptal'),
                ),
              ),
              const SizedBox(width: 16),
              if (detectedCode != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, detectedCode),
                    icon: const Icon(Icons.check),
                    label: const Text('Kullan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
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
