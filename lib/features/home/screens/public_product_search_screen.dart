import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/product_model.dart';
import '../../../features/products/providers/product_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'public_product_detail_screen.dart';

class PublicProductSearchScreen extends StatefulWidget {
  const PublicProductSearchScreen({super.key});

  @override
  State<PublicProductSearchScreen> createState() => _PublicProductSearchScreenState();
}

class _PublicProductSearchScreenState extends State<PublicProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProducts = [];
  String _selectedCategory = 'Tümü';

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
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filterProducts();
    });
  }

  void _filterProducts() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    List<ProductModel> products = productProvider.products;

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      products = products.where((p) => p.category == _selectedCategory).toList();
    }

    // Arama filtresi
    if (_searchController.text.isNotEmpty) {
      products = productProvider.searchProducts(_searchController.text);
      if (_selectedCategory != 'Tümü') {
        products = products.where((p) => p.category == _selectedCategory).toList();
      }
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && _filteredProducts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    productProvider.errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // İlk yüklemede tüm ürünleri göster
          if (_filteredProducts.isEmpty && _searchController.text.isEmpty) {
            _filteredProducts = _selectedCategory == 'Tümü'
                ? productProvider.products
                : productProvider.getProductsByCategory(_selectedCategory);
          }

          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Ürün Ara'),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Ürün adı, marka veya barkod ara...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Category Filter
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isWeb = screenWidth > 600;
                    
                    return isWeb
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((category) {
                                final isSelected = category['name'] == _selectedCategory;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(category['name'] as String),
                                  avatar: Icon(
                                    category['icon'] as IconData,
                                    size: 16,
                                    color: isSelected ? Colors.white : category['color'] as Color,
                                  ),
                                  selectedColor: category['color'] as Color,
                                  checkmarkColor: Colors.white,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category['name'] as String;
                                      _filterProducts();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          )
                        : SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected = category['name'] == _selectedCategory;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: isSelected,
                                    label: Text(category['name'] as String),
                                    avatar: Icon(
                                      category['icon'] as IconData,
                                      size: 18,
                                      color: isSelected ? Colors.white : category['color'] as Color,
                                    ),
                                    selectedColor: category['color'] as Color,
                                    checkmarkColor: Colors.white,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = category['name'] as String;
                                        _filterProducts();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                  },
                ),
              ),

              // Products Grid
              if (_filteredProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Ürün bulunamadı',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isWeb = screenWidth > 600;
                      final crossAxisCount = isWeb ? 4 : 2;
                      final spacing = isWeb ? 16.0 : 8.0;
                      
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: isWeb ? 0.85 : 0.75,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                          childCount: _filteredProducts.length,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

