import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/widgets/product_image_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tümü';
  Timer? _debounceTimer;
  List<ProductModel> _filteredProducts = [];
  bool _isSearchActive = false;

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
    // Ürünleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.loadProducts().then((_) {
        if (mounted) {
          _updateFilteredProducts();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        elevation: 0,
        actions: [
          // Düşük stok uyarısı
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final lowStockCount = productProvider
                  .getLowStockProducts()
                  .length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.warning),
                    onPressed: lowStockCount > 0 ? _showLowStockDialog : null,
                  ),
                  if (lowStockCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$lowStockCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtreleme
          _buildSearchAndFilter(),

          // Ürün Listesi
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          productProvider.errorMessage!,
                          style: TextStyle(color: Colors.grey[600]),
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

                List<ProductModel> products = _getFilteredProducts(
                  productProvider,
                );

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Arama kriterlerine uygun ürün bulunamadı'
                              : 'Henüz ürün eklenmemiş',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('İlk Ürünü Ekle'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => productProvider.loadProducts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAdmin) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: _addProduct,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Arama çubuğu
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ürün adı, marka, barkod veya kategori ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
          ),

          const SizedBox(height: 12),

          // Kategori filtresi
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _updateFilteredProducts();
                    },
                    backgroundColor: Colors.white,
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

  Widget _buildProductCard(ProductModel product) {
    final isLowStock = product.stock <= product.minStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: GestureDetector(
          onTap: product.imageUrls.isNotEmpty
              ? () => _showProductImages(product)
              : null,
          child: ProductImageWidget(
            product: product,
            size: 60,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand.isNotEmpty) ...[
              Text(product.brand),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${product.stock.toStringAsFixed(product.stock == product.stock.toInt() ? 0 : 1)} ${product.unit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₺${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return PopupMenuButton<String>(
              onSelected: (value) => _handleProductAction(value, product),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Görüntüle'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (authProvider.isAdmin) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Düzenle'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'stock',
                    child: ListTile(
                      leading: Icon(Icons.inventory),
                      title: Text('Stok Güncelle'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Sil', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  void _onSearchChanged(String value) {
    // Debounce arama işlemini optimize etmek için
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateFilteredProducts();
      }
    });
  }

  void _updateFilteredProducts() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    List<ProductModel> products = productProvider.products;

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      products = productProvider.getProductsByCategory(_selectedCategory);
    }

    // Arama filtresi
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.trim();
      if (searchQuery.length >= 1) {
        _isSearchActive = true;
        // Kategori filtresine ek olarak arama da uygula
        if (_selectedCategory != 'Tümü') {
          // Önce kategori filtresi uygula, sonra arama
          final categoryProducts = productProvider.getProductsByCategory(
            _selectedCategory,
          );
          products = categoryProducts.where((product) {
            final query = searchQuery.toLowerCase();
            return product.name.toLowerCase().contains(query) ||
                product.brand.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query) ||
                product.barcode.contains(query) ||
                product.description.toLowerCase().contains(query);
          }).toList();
        } else {
          // Sadece arama filtresi
          products = productProvider.searchProducts(searchQuery);
        }
      } else {
        _isSearchActive = false;
      }
    } else {
      _isSearchActive = false;
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  List<ProductModel> _getFilteredProducts(ProductProvider productProvider) {
    // Optimize edilmiş filtreleme için cached results kullan
    return _filteredProducts.isEmpty &&
            !_isSearchActive &&
            _selectedCategory == 'Tümü'
        ? productProvider.products
        : _filteredProducts;
  }

  void _addProduct() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddProductScreen()));

    if (result == true) {
      // Liste güncellendi, yenile
      if (mounted) {
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).loadProducts().then((_) {
          _updateFilteredProducts();
        });
      }
    }
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'view':
        _showProductDetails(product);
        break;
      case 'edit':
        _editProduct(product);
        break;
      case 'stock':
        _updateStock(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
    }
  }

  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand.isNotEmpty) ...[
              Text('Marka: ${product.brand}'),
              const SizedBox(height: 8),
            ],
            Text('Kategori: ${product.category}'),
            const SizedBox(height: 8),
            Text(
              'Fiyat: ₺${product.price.toStringAsFixed(2)} / ${product.unit}',
            ),
            const SizedBox(height: 8),
            Text('Stok: ${product.stock} ${product.unit}'),
            const SizedBox(height: 8),
            Text('Min. Stok: ${product.minStock} ${product.unit}'),
            if (product.barcode.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Barkod: ${product.barcode}'),
            ],
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Açıklama:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(product.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _editProduct(ProductModel product) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );

    if (result == true) {
      // Liste güncellendi, yenile
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      }
    }
  }

  void _updateStock(ProductModel product) {
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.name} - Stok Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'Yeni Stok Miktarı',
                suffixText: product.unit,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Güncelleme Sebebi',
                hintText: 'Örnek: Sayım düzeltmesi',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = double.tryParse(stockController.text);
              if (newStock != null) {
                try {
                  await Provider.of<ProductProvider>(
                    context,
                    listen: false,
                  ).updateStock(
                    product.id,
                    newStock,
                    reasonController.text.isEmpty
                        ? 'Manuel güncelleme'
                        : reasonController.text,
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stok başarıyla güncellendi'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Sil'),
        content: Text(
          '${product.name} ürününü silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              try {
                await Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ).deleteProduct(product.id);

                if (mounted) {
                  Navigator.of(context).pop();
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
                      content: Text('Hata: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showProductImages(ProductModel product) {
    if (product.imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductImageFullScreen(
          imageUrls: product.imageUrls,
          productName: product.name,
        ),
      ),
    );
  }

  void _showLowStockDialog() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final lowStockProducts = productProvider.getLowStockProducts();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Düşük Stok Uyarısı'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final product = lowStockProducts[index];
              return ListTile(
                leading: ProductImageWidget(product: product, size: 40),
                title: Text(product.name),
                subtitle: Text('${product.stock} ${product.unit} kaldı'),
                trailing: Text(
                  'Min: ${product.minStock}',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
