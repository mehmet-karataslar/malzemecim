import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arama')),
      body: Column(
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün adı, marka, barkod veya SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
              onSubmitted: _performSearch,
            ),
          ),

          // Search Results or Empty State
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildEmptyState(),
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
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Mock search results
    final mockResults = [
      {
        'name': 'Vida M8x20',
        'brand': 'Koçtaş',
        'price': 2.50,
        'stock': 150,
        'unit': 'adet',
        'barcode': '1234567890123',
      },
      {
        'name': 'Dış Cephe Boyası',
        'brand': 'Marshall',
        'price': 285.00,
        'stock': 8,
        'unit': 'litre',
        'barcode': '2345678901234',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: mockResults.length,
      itemBuilder: (context, index) {
        final product = mockResults[index];
        return _buildSearchResultCard(product);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${product['brand']}'),
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
                Text('• Stok: ${product['stock']} ${product['unit']}'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  void _performSearch(String query) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Aranıyor: $query')));
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
}
