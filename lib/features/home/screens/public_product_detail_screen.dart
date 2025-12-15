import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PublicProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const PublicProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<PublicProductDetailScreen> createState() => _PublicProductDetailScreenState();
}

class _PublicProductDetailScreenState extends State<PublicProductDetailScreen> {
  UserModel? _business;
  bool _isLoadingBusiness = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  Future<void> _loadBusinessInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(widget.product.createdBy)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _business = UserModel.fromFirestore(doc);
          _isLoadingBusiness = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoadingBusiness = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBusiness = false);
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: kIsWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ürün Görselleri
            if (product.imageUrls.isNotEmpty)
              _buildImageCarousel(product.imageUrls, isWeb)
            else
              Container(
                height: isWeb ? 400 : 300,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),

            // Ürün Bilgileri
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün Adı
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Marka
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: isWeb ? 18 : 16,
                        color: Colors.grey[600],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Fiyat ve Stok
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fiyat',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.price.toStringAsFixed(2)} ₺',
                            style: TextStyle(
                              fontSize: isWeb ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > product.minStock
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: product.stock > product.minStock
                                ? Colors.green
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Stok',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.stock.toStringAsFixed(0)} ${product.unit}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: product.stock > product.minStock
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Ürün Detayları
                  _buildSectionTitle('Ürün Detayları'),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.category,
                    label: 'Kategori',
                    value: product.category,
                  ),
                  if (product.barcode.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.qr_code,
                      label: 'Barkod',
                      value: product.barcode,
                    ),
                  if (product.sku.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.tag,
                      label: 'SKU',
                      value: product.sku,
                    ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailCard(
                      icon: Icons.description,
                      label: 'Açıklama',
                      value: product.description,
                      isDescription: true,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // İşletme Bilgileri
                  _buildSectionTitle('İşletme Bilgileri'),
                  const SizedBox(height: 12),
                  if (_isLoadingBusiness)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_business != null)
                    _buildBusinessCard(_business!)
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'İşletme bilgileri yüklenemedi',
                        style: TextStyle(color: Colors.grey),
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

  Widget _buildImageCarousel(List<String> imageUrls, bool isWeb) {
    return Container(
      height: isWeb ? 500 : 350,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: imageUrls[index],
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
                  debugPrint('Image error in detail screen: $error');
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 64, color: Colors.grey),
                  );
                },
              );
            },
          ),
          if (imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    bool isDescription = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isDescription ? 14 : 16,
                    fontWeight: isDescription ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(UserModel business) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.businessName ?? business.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (business.businessName != null && business.businessName != business.name)
                      Text(
                        business.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // Email
          InkWell(
            onTap: () => _launchEmail(business.email),
            child: _buildContactRow(
              icon: Icons.email,
              label: 'E-posta',
              value: business.email,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          // İletişim butonları
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchEmail(business.email),
                  icon: const Icon(Icons.email, size: 18),
                  label: const Text('E-posta Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

