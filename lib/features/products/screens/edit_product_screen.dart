import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../shared/models/product_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/image_picker_widget.dart';
import '../../../shared/widgets/barcode_scanner_page.dart';
import '../../../shared/widgets/usb_barcode_listener.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen>
    with UsbBarcodeHandler, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _barcodeController;

  String? _selectedCategory;
  String? _selectedUnit;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Fotoğraf yönetimi
  List<String> _imageUrls = [];
  List<File> _localImages = [];

  // Birim seçenekleri
  final List<String> _units = [
    'Adet',
    'Metre',
    'CM',
    'MM',
    'KG',
    'Gram',
    'Litre',
    'ML',
    'M²',
    'M³',
    'Koli',
    'Paket',
    'Takım',
    'Çift',
    'Düzine',
    'Ton',
  ];

  // Kategori seçenekleri
  final List<String> _categories = [
    'Nalburiye',
    'Boya',
    'Elektrik',
    'Tesisat',
    'Hırdavat',
    'Bahçe',
    'İnşaat',
    'Otomotiv',
    'Temizlik',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();

    // Animasyon controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Form alanlarını ürün verileriyle doldur
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _minStockController = TextEditingController(
      text: widget.product.minStock.toString(),
    );
    _barcodeController = TextEditingController(text: widget.product.barcode);

    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
    _imageUrls = List.from(widget.product.imageUrls);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  void onUsbBarcodeReceived(String barcode) {
    // USB barkod cihazından gelen barkodu işle
    setState(() {
      _barcodeController.text = barcode;
    });

    showBarcodeSuccess(barcode);

    // Focus'u barkod alanından bir sonraki alana geçir
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    return UsbBarcodeListener(
      onBarcodeScanned: handleUsbBarcode,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.05),
                Colors.white,
                AppTheme.primaryColor.withOpacity(0.02),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Modern AppBar
                _buildModernAppBar(),
                // Form Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Ürün Resmi Alanı
                            _buildPhotoSection(),
                            const SizedBox(height: 20),
                            // Ürün Bilgileri
                            _buildProductInfoSection(),
                            const SizedBox(height: 20),
                            // Fiyat ve Stok Bilgileri
                            _buildPriceStockSection(),
                            const SizedBox(height: 20),
                            // Barkod Alanı
                            _buildBarcodeSection(),
                            const SizedBox(height: 20),
                            // Kaydet Butonu
                            _buildSaveButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ürün Düzenle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _buildSectionCard(
      icon: Icons.photo_library,
      iconColor: Colors.purple,
      title: 'Ürün Fotoğrafları',
      child: ImagePickerWidget(
        initialImageUrls: _imageUrls,
        onImagesChanged: (urls) {
          setState(() {
            _imageUrls = urls;
          });
        },
        onLocalImagesChanged: (files) {
          setState(() {
            _localImages = files;
          });
        },
        maxImages: 5,
      ),
    );
  }

  Widget _buildProductInfoSection() {
    return _buildSectionCard(
      icon: Icons.inventory_2,
      iconColor: Colors.blue,
      title: 'Ürün Bilgileri',
      child: Column(
        children: [
          _buildModernTextField(
            controller: _nameController,
            label: 'Ürün Adı',
            hint: 'Örnek: Vida M8x20',
            icon: Icons.inventory,
            iconColor: Colors.blue,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ürün adı gereklidir';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _brandController,
            label: 'Marka',
            hint: 'Örnek: Koçtaş',
            icon: Icons.business,
            iconColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildModernDropdown<String>(
            value: _selectedCategory,
            label: 'Kategori',
            icon: Icons.category,
            iconColor: Colors.green,
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kategori seçimi gereklidir';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _descriptionController,
            label: 'Açıklama',
            hint: 'Ürün hakkında ek bilgiler...',
            icon: Icons.description,
            iconColor: Colors.teal,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  String get stockLabel {
    if (_selectedUnit == null || _selectedUnit!.isEmpty) {
      return 'Mevcut Stok';
    }
    return 'Kaç ${_selectedUnit!.toLowerCase()}';
  }

  String get minStockLabel {
    if (_selectedUnit == null || _selectedUnit!.isEmpty) {
      return 'Min. Stok';
    }
    return 'Min. ${_selectedUnit!.toLowerCase()}';
  }

  String get priceLabel {
    if (_selectedUnit == null || _selectedUnit!.isEmpty) {
      return 'Birim Fiyat (₺)';
    }
    return '${_selectedUnit!} başına fiyat (₺)';
  }

  Widget _buildPriceStockSection() {
    return _buildSectionCard(
      icon: Icons.attach_money,
      iconColor: Colors.amber,
      title: 'Fiyat ve Stok Bilgileri',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildModernTextField(
                  controller: _priceController,
                  label: priceLabel,
                  hint: '0.00',
                  icon: Icons.attach_money,
                  iconColor: Colors.amber,
                  isRequired: true,
                  suffixText: '₺',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Fiyat gereklidir';
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Geçerli bir fiyat giriniz';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildModernDropdown<String>(
                  value: _selectedUnit,
                  label: 'Birim',
                  icon: Icons.straighten,
                  iconColor: Colors.indigo,
                  items: _units.map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUnit = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Birim seçimi gereklidir';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _stockController,
                  label: stockLabel,
                  hint: _selectedUnit != null
                      ? '0 ${_selectedUnit!.toLowerCase()}'
                      : '0',
                  icon: Icons.inventory_2,
                  iconColor: Colors.green,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok miktarı gereklidir';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir miktar giriniz';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernTextField(
                  controller: _minStockController,
                  label: minStockLabel,
                  hint: _selectedUnit != null
                      ? '5 ${_selectedUnit!.toLowerCase()}'
                      : '5',
                  icon: Icons.warning,
                  iconColor: Colors.red,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeSection() {
    return _buildSectionCard(
      icon: Icons.qr_code,
      iconColor: Colors.deepPurple,
      title: 'Barkod Bilgisi',
      child: Row(
        children: [
          Expanded(
            child: _buildModernTextField(
              controller: _barcodeController,
              label: 'Barkod (USB cihaz destekli)',
              hint: 'Barkod numarası',
              icon: Icons.qr_code,
              iconColor: Colors.deepPurple,
              keyboardType: TextInputType.number,
              suffixIcon: Icon(
                Icons.usb,
                color: AppTheme.primaryColor.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _scanBarcode,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAdmin) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _updateProduct,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Ürünü Güncelle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    required Color iconColor,
    bool isRequired = false,
    String? suffixText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          suffixText: suffixText,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required Color iconColor,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 15,
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.arrow_drop_down,
          color: iconColor,
        ),
      ),
    );
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final fileName =
          'products/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Firebase Storage yükleme hatası: $e');
      return null;
    }
  }

  Future<List<String>> _uploadAllImages() async {
    List<String> allImageUrls = List.from(_imageUrls);

    for (File imageFile in _localImages) {
      final url = await _uploadImageToFirebase(imageFile);
      if (url != null) {
        allImageUrls.add(url);
      }
    }

    return allImageUrls;
  }

  void _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannorPage()),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcodeController.text = result;
      });

      // Başarılı tarama bildirimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Barkod başarıyla tarandı: $result'),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fotoğrafları yükle
      final imageUrls = await _uploadAllImages();

      // Ürün verisini hazırla
      final productData = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.replaceAll(',', '.')),
        'unit': _selectedUnit!,
        'stock': double.parse(_stockController.text),
        'minStock': double.parse(
          _minStockController.text.isEmpty ? '5' : _minStockController.text,
        ),
        'barcode': _barcodeController.text.trim(),
        'category': _selectedCategory!,
        'imageUrls': imageUrls,
        'updatedAt': DateTime.now(),
      };

      // Ürünü güncelle
      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).updateProduct(widget.product.id, productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ürün başarıyla güncellendi',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ürün güncellenirken hata oluştu: $e',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
