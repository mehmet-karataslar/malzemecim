import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/barcode_scanner_page.dart';
import '../../../shared/widgets/usb_barcode_listener.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with UsbBarcodeHandler {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  final _barcodeController = TextEditingController();

  String _selectedCategory = 'Nalburiye';
  String _selectedUnit = 'Adet';
  bool _isLoading = false;
  int _currentPage = 0;
  final int _totalPages = 4;

  // Görsel yönetimi
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _webImages = [];
  final ImagePicker _picker = ImagePicker();

  // Kategori verileri
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Nalburiye', 'icon': Icons.hardware, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Boya', 'icon': Icons.format_paint, 'color': const Color(0xFFEC4899)},
    {'name': 'Elektrik', 'icon': Icons.electrical_services, 'color': const Color(0xFFF59E0B)},
    {'name': 'Tesisat', 'icon': Icons.plumbing, 'color': const Color(0xFF3B82F6)},
    {'name': 'Hırdavat', 'icon': Icons.build, 'color': const Color(0xFF10B981)},
    {'name': 'Bahçe', 'icon': Icons.yard, 'color': const Color(0xFF22C55E)},
    {'name': 'İnşaat', 'icon': Icons.construction, 'color': const Color(0xFFEF4444)},
    {'name': 'Otomotiv', 'icon': Icons.directions_car, 'color': const Color(0xFF0EA5E9)},
    {'name': 'Temizlik', 'icon': Icons.cleaning_services, 'color': const Color(0xFF14B8A6)},
    {'name': 'Diğer', 'icon': Icons.more_horiz, 'color': const Color(0xFF6B7280)},
  ];

  final List<String> _units = [
    'Adet', 'Metre', 'CM', 'MM', 'KG', 'Gram',
    'Litre', 'ML', 'M²', 'M³', 'Koli', 'Paket',
    'Takım', 'Çift', 'Düzine', 'Ton',
  ];

  final List<String> _pageNames = [
    'Görseller',
    'Kategori & Bilgiler',
    'Fiyat & Stok',
    'Barkod & Özet',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['barcode'] != null) {
        _barcodeController.text = args['barcode'].toString();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void onUsbBarcodeReceived(String barcode) {
    setState(() => _barcodeController.text = barcode);
    showBarcodeSuccess(barcode);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Color get _currentColor {
    final categoryData = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => _categories.last,
    );
    return categoryData['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return UsbBarcodeListener(
      onBarcodeScanned: handleUsbBarcode,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),
              
              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildImagePage(),
                    _buildCategoryInfoPage(),
                    _buildPriceStockPage(),
                    _buildBarcodeReviewPage(),
                  ],
                ),
              ),
              
              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _currentColor,
      foregroundColor: Colors.white,
      title: Text(_pageNames[_currentPage]),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_currentColor, _currentColor.withOpacity(0.7)],
          ),
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Adım ${_currentPage + 1}/$_totalPages',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_totalPages, (index) {
          final isCompleted = index < _currentPage;
          final isCurrent = index == _currentPage;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? _currentColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (index < _totalPages - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ========== PAGE 1: IMAGES ==========
  Widget _buildImagePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildPageHeader(
            icon: Icons.photo_library,
            title: 'Ürün Görselleri',
            subtitle: 'Ürün için en fazla 5 görsel ekleyebilirsiniz',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 24),

          // Image Upload Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Selected Images Grid
                if (_selectedImages.isNotEmpty || _webImages.isNotEmpty) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: kIsWeb ? _webImages.length : _selectedImages.length,
                    itemBuilder: (context, index) => _buildImageTile(index),
                  ),
                  const SizedBox(height: 24),
                ],

                // Add Image Buttons
                if (_selectedImages.length < 5) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageButton(
                          icon: Icons.photo_library,
                          label: 'Galeriden Seç',
                          color: const Color(0xFF8B5CF6),
                          onPressed: _pickImagesFromGallery,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImageButton(
                          icon: Icons.camera_alt,
                          label: 'Fotoğraf Çek',
                          color: const Color(0xFFEC4899),
                          onPressed: _pickImageFromCamera,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Maksimum görsel sayısına ulaşıldı',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'İlk eklediğiniz görsel ana görsel olarak ayarlanacaktır.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PAGE 2: CATEGORY & INFO ==========
  Widget _buildCategoryInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Section
          _buildPageHeader(
            icon: Icons.category,
            title: 'Kategori Seçin',
            subtitle: 'Ürünün ait olduğu kategoriyi belirleyin',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category['name'];
                return _buildCategoryChip(category, isSelected);
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Product Info Section
          _buildPageHeader(
            icon: Icons.info,
            title: 'Ürün Bilgileri',
            subtitle: 'Ürün detaylarını girin',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Product Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Ürün Adı',
                  hint: 'Örnek: Vida M8x20',
                  icon: Icons.inventory_2,
                  isRequired: true,
                ),
                const SizedBox(height: 20),

                // Brand
                _buildTextField(
                  controller: _brandController,
                  label: 'Marka',
                  hint: 'Örnek: Bosch',
                  icon: Icons.business,
                ),
                const SizedBox(height: 20),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  hint: 'Ürün hakkında detaylı bilgi...',
                  icon: Icons.description,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PAGE 3: PRICE & STOCK ==========
  Widget _buildPriceStockPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Section
          _buildPageHeader(
            icon: Icons.attach_money,
            title: 'Fiyat Bilgisi',
            subtitle: 'Ürün birim fiyatını belirleyin',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Price Input with Big Display
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.1),
                        const Color(0xFFF59E0B).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Birim Fiyat',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '₺',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                              ],
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Fiyat gerekli';
                                if (double.tryParse(value!.replaceAll(',', '.')) == null) {
                                  return 'Geçerli fiyat';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Unit Selection
                const Text('Birim Seçin', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _units.map((unit) {
                    final isSelected = _selectedUnit == unit;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedUnit = unit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _currentColor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stock Section
          _buildPageHeader(
            icon: Icons.inventory,
            title: 'Stok Bilgisi',
            subtitle: 'Mevcut ve minimum stok miktarlarını girin',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Current Stock
                Expanded(
                  child: _buildStockInput(
                    controller: _stockController,
                    label: 'Mevcut Stok',
                    color: const Color(0xFF10B981),
                    icon: Icons.inventory_2,
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 16),
                // Minimum Stock
                Expanded(
                  child: _buildStockInput(
                    controller: _minStockController,
                    label: 'Min. Stok',
                    color: const Color(0xFFEF4444),
                    icon: Icons.warning_amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== PAGE 4: BARCODE & REVIEW ==========
  Widget _buildBarcodeReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barcode Section
          _buildPageHeader(
            icon: Icons.qr_code,
            title: 'Barkod',
            subtitle: 'Ürün barkodunu girin veya tarayın',
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 20, letterSpacing: 2),
                        decoration: InputDecoration(
                          labelText: 'Barkod Numarası',
                          hintText: 'USB okuyucu destekli',
                          prefixIcon: const Icon(Icons.qr_code_2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Review Section
          _buildPageHeader(
            icon: Icons.preview,
            title: 'Ürün Özeti',
            subtitle: 'Girdiğiniz bilgileri kontrol edin',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildReviewRow('Ürün Adı', _nameController.text.isEmpty ? '-' : _nameController.text),
                _buildReviewRow('Marka', _brandController.text.isEmpty ? '-' : _brandController.text),
                _buildReviewRow('Kategori', _selectedCategory),
                _buildReviewRow('Fiyat', _priceController.text.isEmpty ? '-' : '₺${_priceController.text}'),
                _buildReviewRow('Birim', _selectedUnit),
                _buildReviewRow('Stok', _stockController.text.isEmpty ? '-' : '${_stockController.text} ${_selectedUnit.toLowerCase()}'),
                _buildReviewRow('Min. Stok', _minStockController.text.isEmpty ? '5' : '${_minStockController.text} ${_selectedUnit.toLowerCase()}'),
                _buildReviewRow('Barkod', _barcodeController.text.isEmpty ? '-' : _barcodeController.text),
                _buildReviewRow('Görseller', '${_selectedImages.length} adet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========
  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.memory(_webImages[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : Image.file(File(_selectedImages[index].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Ana', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category['name'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [category['color'] as Color, (category['color'] as Color).withOpacity(0.7)])
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: (category['color'] as Color).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category['icon'] as IconData, size: 22, color: isSelected ? Colors.white : category['color'] as Color),
            const SizedBox(width: 10),
            Text(
              category['name'] as String,
              style: TextStyle(
                fontSize: 15,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 24.0 : 0),
          child: Icon(icon),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: isRequired ? (value) => value?.isEmpty == true ? '$label gereklidir' : null : null,
    );
  }

  Widget _buildStockInput({
    required TextEditingController controller,
    required String label,
    required Color color,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[300]),
                ),
                validator: isRequired ? (value) => value?.isEmpty == true ? 'Gerekli' : null : null,
              ),
              Text(_selectedUnit.toLowerCase(), style: TextStyle(color: color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 12),
            
            // Next/Save Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : (_currentPage < _totalPages - 1 ? _nextPage : _saveProduct),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_currentPage < _totalPages - 1 ? Icons.arrow_forward : Icons.check),
                label: Text(
                  _isLoading
                      ? 'Kaydediliyor...'
                      : (_currentPage < _totalPages - 1 ? 'İleri' : 'Ürünü Kaydet'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPage < _totalPages - 1 ? _currentColor : AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== METHODS ==========
  Future<void> _pickImagesFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(maxWidth: 800, maxHeight: 800, imageQuality: 70);
      if (images.isNotEmpty) {
        final remaining = 5 - _selectedImages.length;
        for (var image in images.take(remaining)) {
          _selectedImages.add(image);
          if (kIsWeb) _webImages.add(await image.readAsBytes());
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 70);
      if (image != null) {
        _selectedImages.add(image);
        if (kIsWeb) _webImages.add(await image.readAsBytes());
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (kIsWeb && index < _webImages.length) _webImages.removeAt(index);
    });
  }

  void _scanBarcode() async {
    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const BarcodeScannorPage()));
    if (result != null && result.isNotEmpty) {
      setState(() => _barcodeController.text = result);
    }
  }

  Future<List<String>> _uploadImagesToStorage() async {
    List<String> urls = [];
    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final ref = FirebaseStorage.instance.ref().child('products/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        UploadTask task = kIsWeb
            ? ref.putData(_webImages[i], SettableMetadata(contentType: 'image/jpeg'))
            : ref.putFile(File(_selectedImages[i].path));
        final snapshot = await task;
        urls.add(await snapshot.ref.getDownloadURL());
      } catch (e) {
        print('Upload error: $e');
      }
    }
    return urls;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen zorunlu alanları doldurun'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = await _uploadImagesToStorage();
      final productData = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.replaceAll(',', '.')),
        'unit': _selectedUnit,
        'stock': double.parse(_stockController.text),
        'minStock': double.parse(_minStockController.text.isEmpty ? '5' : _minStockController.text),
        'barcode': _barcodeController.text.trim(),
        'category': _selectedCategory,
        'imageUrls': imageUrls,
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'createdBy': context.read<AuthProvider>().currentUser?.id ?? '',
      };

      await context.read<ProductProvider>().addProduct(productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Ürün eklendi!')]),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
