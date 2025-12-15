import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/barcode_scanner_page.dart';
import '../../../shared/widgets/usb_barcode_listener.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/sales_provider.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

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
  bool _isGridView = true;

  // Kategori seçenekleri
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tümü', 'icon': Icons.apps, 'color': const Color(0xFF6366F1)},
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            return CustomScrollView(
              slivers: [
                // Custom App Bar
                _buildSliverAppBar(productProvider),

                // Search Bar
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),

                // Category Filter
                SliverToBoxAdapter(
                  child: _buildCategoryFilter(),
                ),

                // Products
                if (productProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (productProvider.errorMessage != null)
                  SliverFillRemaining(
                    child: _buildErrorState(productProvider),
                  )
                else
                  _buildProductsGrid(productProvider),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (!authProvider.isAdmin) return const SizedBox.shrink();

            return FloatingActionButton.extended(
              onPressed: () => _navigateToAddProduct(),
              icon: const Icon(Icons.add),
              label: const Text('Ürün Ekle'),
              backgroundColor: AppTheme.primaryColor,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ProductProvider productProvider) {
    final selectedCat = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => _categories[0],
    );

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: selectedCat['color'] as Color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                selectedCat['color'] as Color,
                (selectedCat['color'] as Color).withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ürünler',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${productProvider.products.length} ürün',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Grid/List Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isGridView ? Icons.grid_view : Icons.list,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() => _isGridView = !_isGridView);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Refresh
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () => productProvider.loadProducts(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ürün adı, marka veya barkod ara...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // USB Icon
              Tooltip(
                message: 'USB Barkod Destekli',
                child: Icon(
                  Icons.usb,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              // Camera Scan
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                onPressed: _scanBarcodeWithCamera,
              ),
              // Clear
              if (_isSearchActive)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name'] as String;
              });
              _updateFilteredProducts();
            },
            child: Container(
              width: 75,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                category['color'] as Color,
                                (category['color'] as Color).withOpacity(0.7),
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: (category['color'] as Color).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : category['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? category['color'] as Color
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ProductProvider productProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text('Hata: ${productProvider.errorMessage}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => productProvider.loadProducts(),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(ProductProvider productProvider) {
    final products = _getFilteredProducts(productProvider.products);

    if (products.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    if (_isGridView) {
      // MediaQuery ile ekran genişliğini al
      final screenWidth = MediaQuery.of(context).size.width;
      int crossAxisCount;
      double childAspectRatio;

      if (screenWidth >= 1400) {
        // Büyük ekranlar (Web) - 6 sütun
        crossAxisCount = 6;
        childAspectRatio = 0.58;
      } else if (screenWidth >= 1200) {
        // Geniş ekranlar - 5 sütun
        crossAxisCount = 5;
        childAspectRatio = 0.58;
      } else if (screenWidth >= 900) {
        // Orta-geniş ekranlar - 4 sütun
        crossAxisCount = 4;
        childAspectRatio = 0.60;
      } else if (screenWidth >= 600) {
        // Tablet - 3 sütun
        crossAxisCount = 3;
        childAspectRatio = 0.60;
      } else {
        // Mobil - 2 sütun
        crossAxisCount = 2;
        childAspectRatio = 0.55;
      }

      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProductGridCard(products[index]),
            childCount: products.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProductListCard(products[index]),
            childCount: products.length,
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    if (_isSearchActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ürün bulunamadı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı anahtar kelimeler deneyin',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2, size: 48, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz ürün yok',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk ürününüzü eklemek için butona tıklayın',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(ProductModel product) {
    final isLowStock = product.stock <= product.minStock;
    final categoryData = _categories.firstWhere(
      (c) => c['name'] == product.category,
      orElse: () => _categories.last,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Kart boyutuna göre font ve padding ayarla
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 150;
        final isVeryCompact = cardWidth < 120;

        final titleFontSize = isVeryCompact ? 10.0 : (isCompact ? 11.0 : 14.0);
        final priceFontSize = isVeryCompact ? 11.0 : (isCompact ? 12.0 : 16.0);
        final brandFontSize = isVeryCompact ? 8.0 : (isCompact ? 9.0 : 11.0);
        final stockFontSize = isVeryCompact ? 8.0 : (isCompact ? 9.0 : 11.0);
        final iconSize = isVeryCompact ? 20.0 : (isCompact ? 28.0 : 40.0);
        final padding = isVeryCompact ? 6.0 : (isCompact ? 8.0 : 12.0);
        final borderRadius = isVeryCompact ? 8.0 : (isCompact ? 10.0 : 16.0);
        final badgePaddingH = isVeryCompact ? 4.0 : (isCompact ? 5.0 : 8.0);
        final badgePaddingV = isVeryCompact ? 2.0 : (isCompact ? 2.0 : 4.0);

        return GestureDetector(
          onTap: () => _navigateToProductDetail(product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 6, // 3:2 yerine 6:5 oranı (Görsel biraz daha küçülecek, içerik artacak)
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                        child: product.imageUrls.isNotEmpty
                            ? (kIsWeb
                                ? Image.network(
                                    product.imageUrls.first,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: SizedBox(
                                            width: iconSize * 0.5,
                                            height: iconSize * 0.5,
                                            child: const CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: (categoryData['color'] as Color).withOpacity(0.1),
                                      child: Icon(
                                        categoryData['icon'] as IconData,
                                        size: iconSize,
                                        color: categoryData['color'] as Color,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: product.imageUrls.first,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: SizedBox(
                                          width: iconSize * 0.5,
                                          height: iconSize * 0.5,
                                          child: const CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: (categoryData['color'] as Color).withOpacity(0.1),
                                      child: Icon(
                                        categoryData['icon'] as IconData,
                                        size: iconSize,
                                        color: categoryData['color'] as Color,
                                      ),
                                    ),
                                  ))
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      (categoryData['color'] as Color).withOpacity(0.15),
                                      (categoryData['color'] as Color).withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    categoryData['icon'] as IconData,
                                    size: iconSize,
                                    color: categoryData['color'] as Color,
                                  ),
                                ),
                              ),
                      ),
                      // Low Stock Badge
                      if (isLowStock)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isVeryCompact
                                ? const Icon(Icons.warning, color: Colors.white, size: 10)
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning, color: Colors.white, size: isCompact ? 10 : 12),
                                      if (!isCompact) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          'Düşük',
                                          style: TextStyle(color: Colors.white, fontSize: isCompact ? 8 : 10),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Expanded(
                  flex: 5, // İçeriğe daha fazla yer (eski: 2)
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spacer yerine spaceBetween
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.brand.isNotEmpty && !isVeryCompact) ...[
                              const SizedBox(height: 1),
                              Text(
                                product.brand,
                                style: TextStyle(
                                  fontSize: brandFontSize,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        // const Spacer() yerine MainAxisAlignment.spaceBetween kullanıldı
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '₺${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: priceFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: categoryData['color'] as Color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 3 : 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLowStock
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${product.stock.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: stockFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: isLowStock ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Satış Yap Butonu
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                            onPressed: () => _showQuickSaleDialog(product),
                            icon: Icon(Icons.shopping_cart, size: isVeryCompact ? 12 : 14),
                            label: Text(
                              'Satış',
                              style: TextStyle(fontSize: isVeryCompact ? 10 : 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isVeryCompact ? 8 : 12), // Buton büyütüldü
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
        );
      },
    );
  }

  Widget _buildProductListCard(ProductModel product) {
    final isLowStock = product.stock <= product.minStock;
    final categoryData = _categories.firstWhere(
      (c) => c['name'] == product.category,
      orElse: () => _categories.last,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            height: 70,
            color: Colors.grey[50],
            child: product.imageUrls.isNotEmpty
                ? (kIsWeb
                    ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          categoryData['icon'] as IconData,
                          color: categoryData['color'] as Color,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          categoryData['icon'] as IconData,
                          color: categoryData['color'] as Color,
                        ),
                      ))
                : Icon(
                    categoryData['icon'] as IconData,
                    color: categoryData['color'] as Color,
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Düşük',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.brand.isNotEmpty)
              Text(
                product.brand,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '₺${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: categoryData['color'] as Color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Stok: ${product.stock.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLowStock ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _showQuickSaleDialog(product),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.shopping_cart, size: 20),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _navigateToProductDetail(product),
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
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final products = productProvider.products;

    List<ProductModel> filtered = products.where((product) {
      final categoryMatch =
          _selectedCategory == 'Tümü' || product.category == _selectedCategory;
      if (!categoryMatch) return false;

      if (_searchController.text.isEmpty) return true;

      final searchResults = productProvider.searchProducts(_searchController.text);
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

  void _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true && mounted) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    }
  }

  void _navigateToProductDetail(ProductModel product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
    if (result == true && mounted) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    }
  }

  void _showQuickSaleDialog(ProductModel product) {
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_cart, color: AppTheme.successColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hızlı Satış', style: TextStyle(fontSize: 18)),
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stok Bilgisi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mevcut Stok:'),
                  Text(
                    '${product.stock.toStringAsFixed(0)} ${product.unit}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Adet
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Satış Adedi',
                suffixText: product.unit,
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Fiyat
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Satış Fiyatı (Opsiyonel)',
                prefixText: '₺ ',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Boş bırakılırsa normal fiyat kullanılır',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => _processQuickSale(
              dialogContext,
              product,
              quantityController.text,
              priceController.text,
            ),
            icon: const Icon(Icons.check),
            label: const Text('Satışı Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQuickSale(
    BuildContext dialogContext,
    ProductModel product,
    String quantityStr,
    String priceStr,
  ) async {
    final quantity = double.tryParse(quantityStr);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir miktar girin'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (quantity > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok yetersiz!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    Navigator.pop(dialogContext);

    try {
      final salesProvider = context.read<SalesProvider>();
      final productProvider = context.read<ProductProvider>();
      final authProvider = context.read<AuthProvider>();

      // Fiyat belirleme - boşsa normal fiyat
      double salePrice = product.price;
      if (priceStr.isNotEmpty) {
        final parsedPrice = double.tryParse(priceStr.replaceAll(',', '.'));
        if (parsedPrice != null && parsedPrice > 0) {
          salePrice = parsedPrice;
        }
      }

      // Satış kaydı oluştur
      await salesProvider.addSale(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: salePrice,
        createdBy: authProvider.currentUser?.id ?? '',
        saleType: 'cash',
      );

      // Stok düşür
      final newStock = product.stock - quantity;
      await productProvider.updateStock(product.id, newStock, 'Satış');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${quantity.toStringAsFixed(0)} ${product.unit} satıldı! Toplam: ₺${(quantity * salePrice).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Listeyi yenile
        productProvider.loadProducts();
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
}
