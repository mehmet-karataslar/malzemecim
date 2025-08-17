import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _barcodeController;

  String? _selectedUnit;
  String? _selectedCategory;
  bool _isLoading = false;

  // Birim seçenekleri
  final List<String> _units = [
    'Adet',
    'Metre',
    'Santimetre',
    'Milimetre',
    'Kilogram',
    'Gram',
    'Litre',
    'Mililitre',
    'Metrekare',
    'Metreküp',
    'Koli',
    'Paket',
    'Takım',
    'Çift',
    'Düzine',
    'Gross',
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
    // Form alanlarını mevcut ürün verileriyle doldur
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

    _selectedUnit = widget.product.unit;
    _selectedCategory = widget.product.category;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Düzenle'),
        elevation: 0,
        actions: [
          // Kaydet butonu
          TextButton.icon(
            onPressed: _isLoading ? null : _updateProduct,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Ürün Bilgileri
              _buildProductInfoSection(),

              const SizedBox(height: 24),

              // Fiyat ve Stok Bilgileri
              _buildPriceStockSection(),

              const SizedBox(height: 24),

              // Barkod Alanı
              _buildBarcodeSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ürün Bilgileri',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Ürün Adı
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı *',
                hintText: 'Örnek: Vida M8x20',
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ürün adı gereklidir';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Marka
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marka',
                hintText: 'Örnek: Koçtaş',
                prefixIcon: Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 16),

            // Kategori Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori *',
                prefixIcon: Icon(Icons.category),
              ),
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

            // Açıklama
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Ürün açıklaması...',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStockSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fiyat ve Stok',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Fiyat ve Birim (Aynı satırda)
            Row(
              children: [
                // Fiyat
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Birim Fiyat *',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: '₺',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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

                // Birim
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Birim *',
                      prefixIcon: Icon(Icons.straighten),
                    ),
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

            // Stok ve Minimum Stok (Aynı satırda)
            Row(
              children: [
                // Mevcut Stok
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Mevcut Stok *',
                      hintText: '0',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
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

                // Minimum Stok
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Min. Stok',
                      hintText: '5',
                      prefixIcon: Icon(Icons.warning),
                    ),
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
      ),
    );
  }

  Widget _buildBarcodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Barkod',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barkod',
                hintText: 'Barkod numarası',
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Fiyatı parse et
      double price = double.parse(_priceController.text.replaceAll(',', '.'));
      double stock = double.parse(_stockController.text);
      double? minStock = _minStockController.text.isNotEmpty
          ? double.parse(_minStockController.text)
          : null;

      final productData = {
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'unit': _selectedUnit!,
        'stock': stock,
        'minStock': minStock ?? 5.0,
        'category': _selectedCategory!,
        'barcode': _barcodeController.text.trim(),
        'updatedAt': DateTime.now(),
        'updatedBy': authProvider.currentUser?.id ?? '',
      };

      await productProvider.updateProduct(widget.product.id, productData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla güncellendi!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // true dönerek liste güncellemesini tetikle
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün güncellenirken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
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
