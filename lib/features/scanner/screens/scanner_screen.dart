import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/camera_helper_stub.dart'
    if (dart.library.html) '../../../shared/utils/camera_helper_web.dart'
    if (dart.library.io) '../../../shared/utils/camera_helper_windows.dart' as camera_helper;
import 'dart:io' if (dart.library.html) '../../../shared/utils/platform_stub.dart' as io;

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

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      // Windows'ta camera paketi ile kamera listesini al (Web değilse)
      if (!kIsWeb) {
        try {
          // Platform kontrolü için conditional import kullan
          final isWindows = _isWindowsPlatform();
          if (isWindows) {
            // Kamera listesini al (USB telefonlar dahil)
            _availableCameras = await camera_helper.CameraHelper.getAvailableCameras();
            
            // Telefon kameralarını öncelikle göster
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
          } else {
            // Windows değilse normal akış
            setState(() {
              _isInitializing = false;
              _hasError = false;
            });
          }
        } catch (e) {
          debugPrint('Windows kamera hatası: $e');
          setState(() {
            _isInitializing = false;
            _hasError = false;
            // Hata olsa bile manuel giriş kullanılabilir
          });
        }
        return;
      }

      // Web ve mobil için scanner controller oluştur
      // Web için optimize edilmiş ayarlar - net görüntü için
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

      // Controller'ın başlatılmasını bekle (Web için daha uzun süre)
      await Future.delayed(Duration(milliseconds: kIsWeb ? 2000 : 1500));

      // Web ve Windows için kamera listesini al (mobile_scanner kamera açtıktan sonra)
      if (kIsWeb || (!kIsWeb && _isWindowsPlatform())) {
        try {
          _availableCameras = await camera_helper.CameraHelper.getAvailableCameras();
          if (_availableCameras.isNotEmpty) {
            _selectedCamera = _availableCameras.first;
          }
        } catch (e) {
          debugPrint('Kamera listesi alınamadı: $e');
          // Devam et, liste olmadan da çalışır
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
        _errorMessage = 'Kamera başlatılamadı: $e\n\nLütfen:\n${kIsWeb ? '1. Tarayıcı ayarlarından kamera iznini verin\n2. HTTPS veya localhost kullanın\n' : isWindows ? '1. Windows Ayarlar > Gizlilik > Kamera\'dan izin verin\n2. Başka bir uygulama kamerayı kullanmıyorsa kontrol edin\n' : '1. Uygulama ayarlarından kamera iznini verin\n'}3. USB bağlı telefon için telefonunuzda "USB Debugging" veya "File Transfer" modunu açın';
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
        title: const Text('Barkod Tarayıcı'),
        actions: [
          // Web ve Windows için kamera seçimi
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && _availableCameras.length > 1)
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: _showCameraSelector,
              tooltip: 'Kamera Seç',
            ),
          // Web ve Windows için kamera değiştirme
          if ((kIsWeb || (!kIsWeb && _isWindowsPlatform())) && scannerController != null)
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: () {
                scannerController?.switchCamera();
              },
              tooltip: 'Kamera Değiştir',
            ),
          // Odaklanma butonu
          if (scannerController != null)
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _triggerFocus,
              tooltip: 'Odaklan',
            ),
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleScanning,
            tooltip: isScanning ? 'Duraklat' : 'Başlat',
          ),
          // Web'de flash desteklenmiyor
          if (!kIsWeb)
            IconButton(
              icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
              tooltip: 'Flaş',
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            children: [
              // Scanner Area
              Expanded(flex: 4, child: _buildScannerArea()),

              // Info Panel
              Expanded(flex: 3, child: _buildInfoPanel(authProvider)),
            ],
          );
        },
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
    return Container(
      margin: EdgeInsets.all(kIsWeb ? 24 : 16),
      constraints: kIsWeb 
        ? const BoxConstraints(maxWidth: 1200, maxHeight: 800)
        : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kIsWeb ? 20 : 16),
        border: Border.all(
          color: AppTheme.primaryColor, 
          width: kIsWeb ? 4 : 2,
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
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 14),
        child: Stack(
          children: [
            if (scannerController != null)
              AspectRatio(
                aspectRatio: kIsWeb ? 16 / 9 : 4 / 3,
                child: MobileScanner(
                  controller: scannerController!,
                  onDetect: (BarcodeCapture capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && isScanning) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty) {
                        setState(() {
                          lastScannedCode = code;
                          isScanning = false;
                        });
                        _searchProduct(code);
                      }
                    }
                  },
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Put the content into an Expanded SingleChildScrollView so it
          // can scroll when there's not enough vertical space (prevents
          // RenderFlex overflow inside the parent Expanded).
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarama Durumu',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),

                  // Scan Status
                  Row(
                    children: [
                      Icon(
                        isScanning ? Icons.qr_code_scanner : Icons.pause_circle,
                        color: isScanning
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isScanning ? 'Tarama aktif' : 'Tarama duraklatıldı',
                        style: TextStyle(
                          color: isScanning
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Last Scanned Code
                  if (lastScannedCode != null) ...[
                    Text(
                      'Son Taranan Kod:',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        lastScannedCode!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _searchProduct(lastScannedCode!),
                            icon: const Icon(Icons.search),
                            label: const Text('Ürün Ara'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (authProvider.isAdmin)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _addNewProduct(lastScannedCode!),
                              icon: const Icon(Icons.add),
                              label: const Text('Yeni Ürün'),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    // No scan yet
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2, size: 48, color: Colors.blue[600]),
                          const SizedBox(height: 8),
                          Text(
                            'Barkod veya QR kodu taramak için\nkamerayı ürün üzerine tutun',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blue[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Quick Actions (Admin only)
                  if (authProvider.isAdmin && lastScannedCode != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    Text(
                      'Hızlı İşlemler',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
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
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.surfaceColor,
    );
  }

  void _toggleScanning() {
    setState(() {
      isScanning = !isScanning;
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

  void _searchProduct(String code) async {
    // Ürün arama için search screen'e yönlendir
    Navigator.pushNamed(context, '/search');

    // Kısa bir delay ile arama yapılacak kodu search provider'a gönder
    await Future.delayed(const Duration(milliseconds: 500));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barkod ile arama: $code'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'Ara',
          onPressed: () {
            Navigator.pushNamed(context, '/search');
          },
        ),
      ),
    );
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
              _searchProduct(value);
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
                _searchProduct(controller.text);
              }
            },
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }
}
