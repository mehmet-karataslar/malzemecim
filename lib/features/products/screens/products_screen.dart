import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/product_image_widget.dart';
import '../../../shared/widgets/barcode_scanner_page.dart';
import '../../../shared/widgets/usb_barcode_listener.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product_model.dart';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with UsbBarcodeHandler {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<ProductModel> _filteredProducts = [];
  String _selectedCategory = 'Tümü';
  bool _isSearchActive = false;

  // Kategori seçenekleri
  final List<String> _categories = [
    'Tümü',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void onUsbBarcodeReceived(String barcode) {
    // USB barkod cihazından gelen barkodu işle
    setState(() {
      _searchController.text = barcode;
    });

    _onSearchChanged(barcode);
    showBarcodeSuccess(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return UsbBarcodeListener(
      onBarcodeScanned: handleUsbBarcode,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ürünler'),
          elevation: 0,
          actions: [
            // Yenile butonu
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ).loadProducts();
              },
            ),
            // Ürün ekle butonu
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isAdmin) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      Provider.of<ProductProvider>(
                        context,
                        listen: false,
                      ).loadProducts();
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hata: ${productProvider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => productProvider.loadProducts(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            final products = _getFilteredProducts(productProvider.products);

            return Column(
              children: [
                // Arama ve Filtre Alanı
                _buildSearchAndFilter(),

                // Ürün Listesi
                Expanded(
                  child: products.isEmpty
                      ? _buildEmptyState()
                      : _buildProductList(products),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (!authProvider.isAdmin) return const SizedBox.shrink();

            return FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
                if (result == true && mounted) {
                  Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).loadProducts();
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Arama Alanı
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Ürün Ara (USB barkod destekli)',
              hintText: 'Ürün adı, marka, barkod...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // USB ikonu
                  Icon(
                    Icons.usb,
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // Kamera tarama butonu
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcodeWithCamera,
                    tooltip: 'Kamera ile Barkod Tara',
                    iconSize: 20,
                  ),
                  // Temizle butonu
                  if (_isSearchActive)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      iconSize: 20,
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearchChanged,
          ),

          const SizedBox(height: 12),

          // Kategori Filtreleme
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _updateFilteredProducts();
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_isSearchActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Arama sonucu bulunamadı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Farklı anahtar kelimeler deneyin',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Henüz ürün eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk ürününüzü eklemek için + butonuna tıklayın',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<ProductModel> products) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<ProductProvider>(
          context,
          listen: false,
        ).loadProducts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isLowStock = product.stock <= product.minStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: ProductImageWidget(
          product: product,
          size: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand.isNotEmpty) Text('Marka: ${product.brand}'),
            Text('Fiyat: ${product.price.toStringAsFixed(2)} ₺'),
            Row(
              children: [
                Text(
                  'Stok: ${product.stock.toStringAsFixed(0)} ${product.unit}',
                ),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const Text(
                    ' Düşük Stok',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ],
            ),
            if (product.barcode.isNotEmpty)
              Text(
                'Barkod: ${product.barcode}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (!authProvider.isAdmin) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, product),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearchActive = query.isNotEmpty;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateFilteredProducts();
    });
  }

  void _updateFilteredProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final products = productProvider.products;

    List<ProductModel> filtered = products.where((product) {
      // Kategori filtresi
      final categoryMatch =
          _selectedCategory == 'Tümü' || product.category == _selectedCategory;
      if (!categoryMatch) return false;

      // Arama filtresi
      if (_searchController.text.isEmpty) return true;

      final searchResults = productProvider.searchProducts(
        _searchController.text,
      );
      return searchResults.contains(product);
    }).toList();

    setState(() {
      _filteredProducts = filtered;
    });
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> products) {
    if (_isSearchActive || _selectedCategory != 'Tümü') {
      return _filteredProducts;
    }
    return products;
  }

  void _scanBarcodeWithCamera() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannorPage()),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _searchController.text = result;
      });

      _onSearchChanged(result);

      showBarcodeSuccess(result);
    }
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ürün resmi
              if (product.imageUrls.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ProductImageCarousel(
                    imageUrls: product.imageUrls,
                    productName: product.name,
                  ),
                ),

              // Ürün bilgileri
              _buildDetailRow('Kategori', product.category),
              if (product.brand.isNotEmpty)
                _buildDetailRow('Marka', product.brand),
              _buildDetailRow('Fiyat', '${product.price.toStringAsFixed(2)} ₺'),
              _buildDetailRow(
                'Stok',
                '${product.stock.toStringAsFixed(0)} ${product.unit}',
              ),
              _buildDetailRow(
                'Min. Stok',
                '${product.minStock.toStringAsFixed(0)} ${product.unit}',
              ),
              if (product.barcode.isNotEmpty)
                _buildDetailRow('Barkod', product.barcode),
              if (product.description.isNotEmpty)
                _buildDetailRow('Açıklama', product.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isAdmin) return const SizedBox.shrink();

              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _editProduct(product);
                },
                child: const Text('Düzenle'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, ProductModel product) {
    switch (action) {
      case 'edit':
        _editProduct(product);
        break;
      case 'delete':
        _confirmDelete(product);
        break;
    }
  }

  void _editProduct(ProductModel product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
    if (result == true && mounted) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    }
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text(
          '${product.name} ürününü silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ürün başarıyla silindi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ürün silinirken hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
