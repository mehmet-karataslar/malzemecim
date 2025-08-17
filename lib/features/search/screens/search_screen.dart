import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/widgets/product_image_widget.dart';
import '../../../shared/widgets/barcode_scanner_page.dart';
import '../../../shared/widgets/usb_barcode_listener.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/providers/product_provider.dart';
import '../../products/screens/edit_product_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with UsbBarcodeHandler {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _searchResults = [];
  bool _hasSearched = false;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // Navigation arguments'tan gelen barkod varsa otomatik arama yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['barcode'] != null) {
        final barcode = args['barcode'].toString();
        if (barcode.isNotEmpty) {
          setState(() {
            _searchController.text = barcode;
          });
          _performSearch(barcode);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void onUsbBarcodeReceived(String barcode) {
    _searchWithBarcode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return UsbBarcodeListener(
      onBarcodeScanned: handleUsbBarcode,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ürün Ara'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Arama alanı
            _buildSearchSection(),

            // Sonuçlar
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Ana arama alanı
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Ürün Ara (USB barkod destekli)',
              hintText: 'Ürün adı, marka, barkod veya açıklama...',
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
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _hasSearched = false;
                          _lastSearchQuery = '';
                        });
                      },
                      iconSize: 20,
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _performSearch(value);
              } else if (value.isEmpty) {
                setState(() {
                  _searchResults = [];
                  _hasSearched = false;
                  _lastSearchQuery = '';
                });
              }
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _performSearch(value);
              }
            },
          ),

          const SizedBox(height: 12),

          // Arama butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Ürün Ara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final product = _searchResults[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ürün Arama',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aramak istediğiniz ürünün adını, markasını\nveya barkodunu yazın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Barkod Tarama',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'USB barkod okuyucu veya kamera\nile hızlı arama yapabilirsiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
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
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç Bulunamadı',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$_lastSearchQuery" için sonuç bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Arama İpuçları',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Farklı anahtar kelimeler deneyin\n• Yazım hatası kontrolü yapın\n• Daha genel terimler kullanın\n• Barkod ile arama yapın',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isLowStock = product.stock <= product.minStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: ProductImageWidget(
          imageUrls: product.imageUrls,
          width: 60,
          height: 60,
          borderRadius: 8,
          onTap: () => _showProductImages(product),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand.isNotEmpty)
              Text('Marka: ${product.brand}'),
            Text('Kategori: ${product.category}'),
            Text('Fiyat: ${product.price.toStringAsFixed(2)} ₺'),
            Row(
              children: [
                Text('Stok: ${product.stock.toStringAsFixed(0)} ${product.unit}'),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const Text(' Düşük Stok', style: TextStyle(color: Colors.orange)),
                ],
              ],
            ),
            if (product.barcode.isNotEmpty)
              Text('Barkod: ${product.barcode}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, product),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Detaylar'),
                ],
              ),
            ),
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
          ],
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

    final trimmedQuery = query.trim();
    final isBarcodeFormat = RegExp(r'^\d{8,}$').hasMatch(trimmedQuery);

    List<ProductModel> searchResults;

    if (isBarcodeFormat) {
      // Önce tam barkod eşleşmesi ara
      searchResults = productProvider.products
          .where((product) => product.barcode == trimmedQuery)
          .toList();

      // Tam eşleşme yoksa normal arama yap
      if (searchResults.isEmpty) {
        searchResults = productProvider.searchProducts(trimmedQuery);
      }

      // Barkod ile arama sonucu için özel mesaj
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
      searchResults = productProvider.searchProducts(trimmedQuery);
    }

    setState(() {
      _searchResults = searchResults;
      _hasSearched = true;
      _lastSearchQuery = trimmedQuery;
    });
  }

  void _searchWithBarcode(String barcode) {
    setState(() {
      _searchController.text = barcode;
    });

    _performSearch(barcode);

    // USB barkod bildirimi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('USB Barkod alındı: $barcode'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scanBarcodeWithCamera() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannorPage(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _searchController.text = result;
      });

      _performSearch(result);

      showBarcodeSuccess(result);
    }
  }

  void _showProductImages(ProductModel product) {
    if (product.imageUrls.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductImageFullScreen(
          imageUrls: product.imageUrls,
          initialIndex: 0,
          productName: product.name,
        ),
      ),
    );
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
                  child: ProductImageWidget(
                    imageUrls: product.imageUrls,
                    borderRadius: 8,
                    onTap: () => _showProductImages(product),
                  ),
                ),

              // Ürün bilgileri
              _buildDetailRow('Kategori', product.category),
              if (product.brand.isNotEmpty)
                _buildDetailRow('Marka', product.brand),
              _buildDetailRow('Fiyat', '${product.price.toStringAsFixed(2)} ₺'),
              _buildDetailRow('Stok', '${product.stock.toStringAsFixed(0)} ${product.unit}'),
              _buildDetailRow('Min. Stok', '${product.minStock.toStringAsFixed(0)} ${product.unit}'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editProduct(product);
            },
            child: const Text('Düzenle'),
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
      case 'details':
        _showProductDetails(product);
        break;
      case 'edit':
        _editProduct(product);
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
      // Arama sonuçlarını güncelle
      _performSearch(_searchController.text);
    }
  }
}
