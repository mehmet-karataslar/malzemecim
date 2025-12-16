import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// USB Barkod Okuyucu Entegrasyonu
/// Bu widget USB barkod okuyuculardan gelen input'ları dinler
/// Barkod cihazları genelde klavye emülasyonu yapar
class UsbBarcodeListener extends StatefulWidget {
  final Widget child;
  final Function(String barcode) onBarcodeScanned;
  final bool enabled;
  final int minBarcodeLength;
  final int maxBarcodeLength;
  final Duration inputTimeout;

  const UsbBarcodeListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.enabled = true,
    this.minBarcodeLength = 3,
    this.maxBarcodeLength = 50,
    this.inputTimeout = const Duration(milliseconds: 100),
  });

  @override
  State<UsbBarcodeListener> createState() => _UsbBarcodeListenerState();
}

class _UsbBarcodeListenerState extends State<UsbBarcodeListener> {
  String _scannedChars = '';
  Timer? _inputTimer;
  DateTime? _lastInputTime;
  final FocusNode _focusNode = FocusNode();
  bool _isProcessingBarcode = false;

  @override
  void initState() {
    super.initState();
    // Widget yüklendiğinde focus'u al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled || _isProcessingBarcode) return;

    if (event is KeyDownEvent) {
      final now = DateTime.now();

      // Enter tuşu - barkod tamamlandı
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _processBarcodeInput();
        return;
      }

      // Tab tuşu - bazı cihazlar tab ile bitirir
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        _processBarcodeInput();
        return;
      }

      // Karakter girişi
      final character = event.character;
      if (character != null && character.isNotEmpty) {
        // Hızlı giriş kontrolü (barkod cihazı çok hızlı yazer)
        if (_lastInputTime != null) {
          final timeDiff = now.difference(_lastInputTime!);

          // 50ms'den hızlı giriş = muhtemelen barkod cihazı
          if (timeDiff.inMilliseconds < 50) {
            _scannedChars += character;
          } else if (timeDiff.inMilliseconds > 500) {
            // Uzun ara = yeni barkod başlangıcı
            _scannedChars = character;
          } else {
            // Normal klavye girişi, ignore et veya reset
            _scannedChars = '';
          }
        } else {
          _scannedChars = character;
        }

        _lastInputTime = now;

        // Timeout timer başlat
        _inputTimer?.cancel();
        _inputTimer = Timer(widget.inputTimeout, () {
          _processBarcodeInput();
        });
      }
    }
  }

  void _processBarcodeInput() {
    if (_scannedChars.length >= widget.minBarcodeLength &&
        _scannedChars.length <= widget.maxBarcodeLength) {
      setState(() {
        _isProcessingBarcode = true;
      });

      // Barkod callback'ini çağır
      widget.onBarcodeScanned(_scannedChars.trim());

      // Debug log
      print('🔍 USB Barkod algılandı: $_scannedChars');

      // Reset
      _scannedChars = '';
      _lastInputTime = null;

      // Kısa bir delay sonra tekrar dinlemeye başla
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isProcessingBarcode = false;
          });
        }
      });
    } else {
      // Geçersiz uzunluk, reset
      _scannedChars = '';
      _lastInputTime = null;
    }

    _inputTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          // Tıklandığında focus'u tekrar al
          _focusNode.requestFocus();
        },
        child: widget.child,
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isProcessingBarcode
            ? Colors.orange.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isProcessingBarcode ? Icons.qr_code_scanner : Icons.usb,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _isProcessingBarcode ? 'Taranıyor...' : 'USB Hazır',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// USB Barkod Okuyucu için yardımcı mixin
mixin UsbBarcodeHandler<T extends StatefulWidget> on State<T> {
  void handleUsbBarcode(String barcode) {
    // Alt sınıflarda override edilecek
    onUsbBarcodeReceived(barcode);
  }

  void onUsbBarcodeReceived(String barcode) {
    // Override edilmesi gereken metod
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('USB Barkod: $barcode'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showBarcodeSuccess(String barcode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Barkod alındı: $barcode'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showBarcodeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
