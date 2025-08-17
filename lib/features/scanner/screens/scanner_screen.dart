import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? lastScannedCode;
  bool isScanning = true;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void dispose() {
    _manualInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Tarayıcı'),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleScanning,
          ),
          IconButton(icon: const Icon(Icons.flash_on), onPressed: _toggleFlash),
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
              size: 80,
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
              'Barkod veya QR kod bilgisini manuel olarak giriniz',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _manualInputController,
              decoration: InputDecoration(
                labelText: 'Barkod / QR Kod',
                hintText: '1234567890123',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_manualInputController.text.isNotEmpty) {
                      setState(() {
                        lastScannedCode = _manualInputController.text;
                        isScanning = false;
                      });
                      _searchProduct(_manualInputController.text);
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    lastScannedCode = value;
                    isScanning = false;
                  });
                  _searchProduct(value);
                }
              },
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
          border: Border.all(color: AppTheme.primaryColor, width: 2),
          color: Colors.grey[200],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 60, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Kamera Tarayıcı',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mobil cihazlarda mevcut',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoPanel(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
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
  }

  void _toggleFlash() {
    // Web'de flash özelliği yok
    if (kIsWeb) return;
  }

  void _searchProduct(String code) {
    // TODO: Ürün arama implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ürün aranıyor: $code'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _addNewProduct(String code) {
    // TODO: Yeni ürün ekleme implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yeni ürün ekleniyor: $code'),
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
}
