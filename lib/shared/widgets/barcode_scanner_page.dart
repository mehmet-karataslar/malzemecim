import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false, // Performans için görüntü döndürme
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
          if (!kIsWeb && scannerController != null)
            IconButton(
              icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
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

  Widget _buildScannerArea() {
    if (kIsWeb) {
      // Web için manuel giriş alanı
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 100,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'Web Tarayıcı Modu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Barkod bilgisini manuel olarak giriniz',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    } else {
      // Mobil için kamera tarayıcı
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              if (scannerController != null)
                MobileScanner(
                  controller: scannerController!,
                  onDetect: _onBarcodeDetect,
                )
              else
                const Center(child: CircularProgressIndicator()),

              // Scanning overlay
              _buildScanningOverlay(),
            ],
          ),
        ),
      );
    }
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
}
