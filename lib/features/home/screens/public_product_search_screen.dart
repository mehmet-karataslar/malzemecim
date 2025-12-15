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

          final screenWidth = MediaQuery.of(context).size.width;
          final isWeb = screenWidth > 600;
          
          return Column(
            children: [
              // Fixed Header - Search Bar
              Container(
                color: AppTheme.primaryColor,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              
              // Fixed Category Filter
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: isWeb ? 16 : 8),
                child: isWeb
                    ? Wrap(
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
                      )
                    : SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
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
                      ),
              ),
              
              // Scrollable Products Grid
              Expanded(
                child: _filteredProducts.isEmpty
                    ? Center(
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
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(isWeb ? 16 : 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWeb ? 4 : 2,
                          childAspectRatio: isWeb ? 0.85 : 0.80,
                          crossAxisSpacing: isWeb ? 12 : 8,
                          mainAxisSpacing: isWeb ? 12 : 8,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image - Fixed height
            Container(
              height: isWeb ? 120 : 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
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
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ),

            // Product Info
            Padding(
              padding: EdgeInsets.all(isWeb ? 8 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 12 : 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isWeb ? 3 : 2),
                  Text(
                    product.brand,
                    style: TextStyle(
                      fontSize: isWeb ? 10 : 9,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isWeb ? 4 : 3),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 13,
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

