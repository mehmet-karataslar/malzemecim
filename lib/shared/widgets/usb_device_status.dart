import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// USB Cihaz Durumu Widget'ı
/// Barkod okuyucu ve diğer USB cihazların durumunu gösterir
class UsbDeviceStatus extends StatefulWidget {
  final bool showAlways;
  final EdgeInsets margin;
  
  const UsbDeviceStatus({
    super.key,
    this.showAlways = false,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  State<UsbDeviceStatus> createState() => _UsbDeviceStatusState();
}

class _UsbDeviceStatusState extends State<UsbDeviceStatus> 
    with TickerProviderStateMixin {
  bool _isUsbConnected = false;
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.showAlways) {
      _checkUsbStatus();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkUsbStatus() {
    // USB durumunu kontrol et (platform specific)
    // Android/Windows'ta farklı yöntemler kullanılabilir
    setState(() {
      _isUsbConnected = true; // Varsayılan olarak true
      _isVisible = true;
    });
    
    _animationController.forward();
    
    // 3 saniye sonra gizle (showAlways false ise)
    if (!widget.showAlways) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _hideStatus();
        }
      });
    }
  }

  void _hideStatus() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void showStatus() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible && !widget.showAlways) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: widget.margin,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isUsbConnected 
                    ? AppTheme.successColor.withOpacity(0.9)
                    : AppTheme.warningColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isUsbConnected ? Icons.usb : Icons.usb_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isUsbConnected 
                        ? 'USB Barkod Okuyucu Hazır'
                        : 'USB Cihaz Bağlı Değil',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isUsbConnected) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// USB Barkod Okuyucu Ayarları Dialog
class UsbBarcodeSettings extends StatefulWidget {
  const UsbBarcodeSettings({super.key});

  @override
  State<UsbBarcodeSettings> createState() => _UsbBarcodeSettingsState();
}

class _UsbBarcodeSettingsState extends State<UsbBarcodeSettings> {
  int _minLength = 3;
  int _maxLength = 50;
  int _timeoutMs = 100;
  bool _autoFocus = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.usb, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('USB Barkod Ayarları'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSliderSetting(
              'Min. Barkod Uzunluğu',
              _minLength.toDouble(),
              1, 20,
              (value) => setState(() => _minLength = value.toInt()),
            ),
            
            _buildSliderSetting(
              'Max. Barkod Uzunluğu',
              _maxLength.toDouble(),
              10, 100,
              (value) => setState(() => _maxLength = value.toInt()),
            ),
            
            _buildSliderSetting(
              'Timeout (ms)',
              _timeoutMs.toDouble(),
              50, 500,
              (value) => setState(() => _timeoutMs = value.toInt()),
            ),
            
            SwitchListTile(
              title: const Text('Otomatik Focus'),
              subtitle: const Text('Tarama sonrası sonraki alana geç'),
              value: _autoFocus,
              onChanged: (value) => setState(() => _autoFocus = value),
            ),
            
            SwitchListTile(
              title: const Text('Ses Efekti'),
              subtitle: const Text('Başarılı tarama sesi'),
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            // Ayarları kaydet
            Navigator.pop(context, {
              'minLength': _minLength,
              'maxLength': _maxLength,
              'timeout': _timeoutMs,
              'autoFocus': _autoFocus,
              'soundEnabled': _soundEnabled,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(value.toInt().toString()),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
