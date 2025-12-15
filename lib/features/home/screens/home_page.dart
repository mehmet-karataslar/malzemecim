import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/product_model.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/products/providers/product_provider.dart';
import 'public_product_search_screen.dart';
import 'public_product_detail_screen.dart';
import '../../appointments/screens/book_appointment_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductModel> _featuredProducts = [];
  List<UserModel> _businesses = [];
  int _totalProducts = 0;
  int _totalBusinesses = 0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Nalburiye', 'icon': Icons.hardware, 'color': const Color(0xFF8B5CF6), 'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)]},
    {'name': 'Boya', 'icon': Icons.format_paint, 'color': const Color(0xFFEC4899), 'gradient': [Color(0xFFEC4899), Color(0xFFDB2777)]},
    {'name': 'Elektrik', 'icon': Icons.electrical_services, 'color': const Color(0xFFF59E0B), 'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)]},
    {'name': 'Tesisat', 'icon': Icons.plumbing, 'color': const Color(0xFF3B82F6), 'gradient': [Color(0xFF3B82F6), Color(0xFF2563EB)]},
    {'name': 'Hırdavat', 'icon': Icons.build, 'color': const Color(0xFF10B981), 'gradient': [Color(0xFF10B981), Color(0xFF059669)]},
    {'name': 'Bahçe', 'icon': Icons.yard, 'color': const Color(0xFF22C55E), 'gradient': [Color(0xFF22C55E), Color(0xFF16A34A)]},
    {'name': 'İnşaat', 'icon': Icons.construction, 'color': const Color(0xFFEF4444), 'gradient': [Color(0xFFEF4444), Color(0xFFDC2626)]},
    {'name': 'Otomotiv', 'icon': Icons.directions_car, 'color': const Color(0xFF0EA5E9), 'gradient': [Color(0xFF0EA5E9), Color(0xFF0284C7)]},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Build tamamlandıktan sonra veri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Ürünleri yükle
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProducts();
      
      // Popüler ürünler (ilk 8 ürün)
      setState(() {
        _featuredProducts = productProvider.products.take(8).toList();
        _totalProducts = productProvider.products.length;
      });

      // İşletmeleri yükle
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final businessesList = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.businessName != null && user.businessName!.isNotEmpty)
          .toList();

      setState(() {
        _businesses = businessesList.take(10).toList();
        _totalBusinesses = businessesList.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/app_icon.png',
            fit: BoxFit.contain,
          ),
        ),
        title: const Text(
          'Malzemecim',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAuthenticated) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle, color: AppTheme.primaryColor),
                  onSelected: (value) {
                    if (value == 'logout') {
                      authProvider.signOut();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: const Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Çıkış Yap'),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.login, color: AppTheme.primaryColor),
                  tooltip: 'Giriş Yap',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          const PublicProductSearchScreen(),
          const BookAppointmentScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.home),
              text: 'Anasayfa',
            ),
            Tab(
              icon: Icon(Icons.search),
              text: 'Ürün Ara',
            ),
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Randevu Al',
            ),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistikler
          _buildStatsSection(),

          const SizedBox(height: 24),

          // Kategoriler
          _buildCategoriesSection(),

          const SizedBox(height: 24),

          // Popüler Ürünler
          if (_featuredProducts.isNotEmpty) _buildFeaturedProductsSection(),

          const SizedBox(height: 24),

          // İşletmeler
          if (_businesses.isNotEmpty) _buildBusinessesSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: Icons.inventory_2,
            value: _totalProducts.toString(),
            label: 'Toplam Ürün',
            color: Colors.white,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatCard(
            icon: Icons.business,
            value: _totalBusinesses.toString(),
            label: 'Toplam İşletme',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final crossAxisCount = isWeb ? 8 : 4;
    final childAspectRatio = isWeb ? 1.0 : 0.85;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Kategoriler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: isWeb ? 8 : 12,
              mainAxisSpacing: isWeb ? 8 : 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category, isWeb);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isWeb) {
    final gradient = category['gradient'] as List<Color>;
    return InkWell(
      onTap: () {
        _tabController.animateTo(1);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (category['color'] as Color).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isWeb ? 8 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category['icon'] as IconData,
                color: Colors.white,
                size: isWeb ? 20 : 28,
              ),
            ),
            SizedBox(height: isWeb ? 4 : 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category['name'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWeb ? 9 : 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Popüler Ürünler',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isWeb
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _featuredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _featuredProducts[index];
                    return _buildProductCard(product, isWeb);
                  },
                )
              : SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _featuredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _featuredProducts[index];
                      return _buildProductCard(product, isWeb);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, bool isWeb) {
    final cardWidth = isWeb ? null : 140.0;
    
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: isWeb ? 0 : 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Görsel Bölümü - Sabit yükseklik
              Container(
                height: isWeb ? 160 : 140,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              httpHeaders: kIsWeb ? {
                                'Access-Control-Allow-Origin': '*',
                              } : null,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Image error: $error');
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                    if (product.stock <= product.minStock)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Az Stok',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Bilgi Bölümü
              Padding(
                padding: EdgeInsets.fromLTRB(isWeb ? 10 : 8, isWeb ? 8 : 6, isWeb ? 10 : 8, isWeb ? 8 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 13 : 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isWeb ? 4 : 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '${product.price.toStringAsFixed(2)} ₺',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: isWeb ? 15 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 4 : 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.stock.toStringAsFixed(0)} ${product.unit}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: isWeb ? 9 : 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.store, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'İşletmeler',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              if (_businesses.length > 5)
                TextButton.icon(
                  onPressed: () {
                    _tabController.animateTo(2);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tümünü Gör'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _businesses.length > 6 ? 6 : _businesses.length,
            itemBuilder: (context, index) {
              final business = _businesses[index];
              return _buildBusinessCard(business);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(UserModel business) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            _tabController.animateTo(2);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.businessName ?? business.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business.name,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
