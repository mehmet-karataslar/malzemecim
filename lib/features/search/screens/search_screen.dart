import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/widgets/product_image_widget.dart';
import '../../../shared/widgets/usb_barcode_listener.dart';
import '../../../shared/widgets/barcode_scanner_page.dart';
import '../../products/providers/product_provider.dart';
import '../../products/screens/edit_product_screen.dart';
import '../../../shared/providers/auth_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with UsbBarcodeHandler {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _searchResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Ürünleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void onUsbBarcodeReceived(String barcode) {
    // USB barkod ile direkt arama yap ve ürünü bul
    _searchWithBarcode(barcode);
  }

  void _searchWithBarcode(String barcode) {
    setState(() {
      _searchController.text = barcode;
    });
    
    _performSearch(barcode);
    
    showBarcodeSuccess(barcode);
  }

  void _scanBarcodeWithCamera() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannorPage(),
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      _searchWithBarcode(result);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UsbBarcodeListener(
      onBarcodeScanned: handleUsbBarcode,
      child: Scaffold(
      appBar: AppBar(title: const Text('Ürün Arama'), elevation: 0),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün adı, marka, barkod... (USB & Kamera destekli)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // USB Barkod göstergesi
                    Icon(
                      Icons.usb,
                      size: 18,
                      color: AppTheme.primaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    // Kamera barkod tarama butonu
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scanBarcodeWithCamera,
                      tooltip: 'Kamera ile Barkod Tara',
                      iconSize: 20,
                    ),
                    // Temizle butonu
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                            _hasSearched = false;
                          });
                        },
                        iconSize: 20,
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                // Gerçek zamanlı arama
                if (value.isNotEmpty && value.length >= 2) {
                  _performSearch(value);
                } else if (value.isEmpty) {
                  setState(() {
                    _searchResults.clear();
                    _hasSearched = false;
                  });
                }
              },
              onSubmitted: _performSearch,
            ),
          ),

          // Search Results or States
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && !_hasSearched) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.errorMessage != null && !_hasSearched) {
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

                if (!_hasSearched && _searchController.text.isEmpty) {
                  return _buildEmptyState();
                }

                if (_hasSearched && _searchResults.isEmpty) {
                  return _buildNoResultsState();
                }

                return _buildSearchResults();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ürün aramak için yukarıdaki\narama kutusunu kullanın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Ürün adı, marka, barkod veya\nkategori ile arama yapabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Arama kriterlerine uygun\nürün bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '"${_searchController.text}" için sonuç yok',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<ProductProvider>(
          context,
          listen: false,
        ).loadProducts();
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          return _buildSearchResultCard(product);
        },
      ),
    );
  }

  Widget _buildSearchResultCard(ProductModel product) {
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
            Text('Kategori: ${product.category}'),
            const SizedBox(height: 4),
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
            if (product.barcode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Barkod: ${product.barcode}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
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
                ],
              ],
            );
          },
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    
    // Barkod formatı kontrolü (sayısal ve belirli uzunlukta)
    final trimmedQuery = query.trim();
    final isBarcodeFormat = RegExp(r'^\d{8,}$').hasMatch(trimmedQuery);
    
    List<ProductModel> searchResults;
    
    if (isBarcodeFormat) {
      // Barkod aramasında önce tam eşleşme ara
      searchResults = productProvider.products
          .where((product) => product.barcode == trimmedQuery)
          .toList();
      
      // Tam eşleşme yoksa normal arama yap
      if (searchResults.isEmpty) {
        searchResults = productProvider.searchProducts(trimmedQuery);
      }
      
      // Barkod bulunduğu bilgisini göster
      if (searchResults.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              searchResults.length == 1 
                  ? 'Barkod ile ürün bulundu!'
                  : '${searchResults.length} ürün barkod ile eşleşti'
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Normal arama
      searchResults = productProvider.searchProducts(trimmedQuery);
    }

    setState(() {
      _searchResults = searchResults;
      _hasSearched = true;
    });
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
        await Provider.of<ProductProvider>(
          context,
          listen: false,
        ).loadProducts();
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
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
                    // Arama sonuçlarını güncelle
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
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

  void _showProductImages(ProductModel product) {
    if (product.imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductImageFullScreen(
          imageUrls: product.imageUrls,
          productName: product.name,
        ),
        ), // AlertDialog kapanışı
      ), // Scaffold kapanışı
    ); // UsbBarcodeListener kapanışı
  }
}
