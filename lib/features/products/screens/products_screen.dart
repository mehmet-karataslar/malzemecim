import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tümü';

  final List<String> _categories = [
    'Tümü',
    'Nalburiye',
    'Hırdavat',
    'Boya',
    'Elektrik',
    'Tesisat',
    'İnşaat',
    'Kurulum',
    'Genel',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddProductDialog,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          _buildSearchAndFilter(),

          // Products List
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
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
                    },
                    backgroundColor: AppTheme.surfaceColor,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    // Mock data - gerçek implementasyonda Firebase'den gelecek
    final mockProducts = [
      {
        'name': 'Vida M8x20',
        'brand': 'Koçtaş',
        'price': 2.50,
        'stock': 150,
        'unit': 'adet',
        'category': 'Nalburiye',
        'barcode': '1234567890123',
      },
      {
        'name': 'Dış Cephe Boyası',
        'brand': 'Marshall',
        'price': 285.00,
        'stock': 8,
        'unit': 'litre',
        'category': 'Boya',
        'barcode': '2345678901234',
      },
      {
        'name': 'Elektrik Kablosu 2.5mm',
        'brand': 'Nexans',
        'price': 12.75,
        'stock': 250,
        'unit': 'metre',
        'category': 'Elektrik',
        'barcode': '3456789012345',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockProducts.length,
      itemBuilder: (context, index) {
        final product = mockProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final lowStock = (product['stock'] as int) < 20;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.inventory_2,
            color: AppTheme.primaryColor,
            size: 30,
          ),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${product['brand']} • ${product['category']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '₺${product['price'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text('/ ${product['unit']}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  size: 16,
                  color: lowStock ? AppTheme.errorColor : AppTheme.successColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Stok: ${product['stock']} ${product['unit']}',
                  style: TextStyle(
                    color: lowStock
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                    fontWeight: FontWeight.w500,
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
      ),
    );
  }

  void _handleProductAction(String action, Map<String, dynamic> product) {
    switch (action) {
      case 'view':
        _showProductDetails(product);
        break;
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'stock':
        _showStockUpdateDialog(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Ürün Ekle'),
        content: const Text('Ürün ekleme formu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marka: ${product['brand']}'),
            Text('Kategori: ${product['category']}'),
            Text('Fiyat: ₺${product['price'].toStringAsFixed(2)}'),
            Text('Stok: ${product['stock']} ${product['unit']}'),
            Text('Barkod: ${product['barcode']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ürün düzenleme özelliği yakında...')),
    );
  }

  void _showStockUpdateDialog(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stok güncelleme özelliği yakında...')),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Sil'),
        content: Text(
          '${product['name']} ürününü silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ürün silme özelliği yakında...')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
