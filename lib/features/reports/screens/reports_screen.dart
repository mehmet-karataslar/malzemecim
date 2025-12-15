import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/credit_model.dart';
import '../../../shared/models/sales_model.dart';
import '../../products/providers/product_provider.dart';
import '../../products/providers/sales_provider.dart';
import '../../credit/providers/credit_provider.dart';

// Helper to create a color with opacity without using deprecated getters
Color _withOpacity(Color color, double opacity) {
  final int a = (opacity * 255).round() & 0xFF;
  return Color((a << 24) | (color.toARGB32() & 0x00FFFFFF));
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    // Verileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CreditProvider>().loadCredits();
      context.read<SalesProvider>().loadAllSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: Consumer2<ProductProvider, CreditProvider>(
        builder: (context, productProvider, creditProvider, child) {
          final lowStockProducts = productProvider.getLowStockProducts();
          final totalCreditAmount = creditProvider.totalCreditAmount;
          final activeCreditCount = creditProvider.activeCreditCount;

          final items = [
            {
              'title': 'Düşük Stok',
              'icon': Icons.trending_down,
              'color': AppTheme.errorColor,
              'subtitle': '${lowStockProducts.length} ürün',
              'onTap': () => _showLowStockReport(context, lowStockProducts),
            },
            {
              'title': 'Veresiye Toplam',
              'icon': Icons.account_balance_wallet,
              'color': AppTheme.warningColor,
              'subtitle': '₺${totalCreditAmount.toStringAsFixed(2)} ($activeCreditCount kayıt)',
              'onTap': () => _showCreditSummary(context, creditProvider),
            },
            {
              'title': 'En Çok Aranan',
              'icon': Icons.trending_up,
              'color': AppTheme.successColor,
              'subtitle': '${productProvider.products.length} ürün',
              'onTap': () => _showPopularProducts(context, productProvider.products),
            },
            {
              'title': 'Aylık Özet',
              'icon': Icons.calendar_month,
              'color': AppTheme.primaryColor,
              'subtitle': _getCurrentMonth(),
              'onTap': () => _showMonthlySummary(context, productProvider, creditProvider),
            },
            {
              'title': 'Satış Geçmişi',
              'icon': Icons.receipt_long,
              'color': const Color(0xFF8B5CF6),
              'subtitle': 'Detaylı ürün çıkışı',
              'onTap': () => _showSalesHistory(context),
            },
          ];

          return RefreshIndicator(
            onRefresh: () async {
              await productProvider.loadProducts();
              await creditProvider.loadCredits();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final it = items[index];
                return _buildReportCard(
                  context,
                  title: it['title'] as String,
                  icon: it['icon'] as IconData,
                  color: it['color'] as Color,
                  subtitle: it['subtitle'] as String,
                  onTap: it['onTap'] as VoidCallback,
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getCurrentMonth() {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_withOpacity(color, 0.12), Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: _withOpacity(color, 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: _withOpacity(color, 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, _withOpacity(color, 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _withOpacity(color, 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                fontSize: 18,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _withOpacity(color, 0.85),
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.chevron_right, size: 20, color: _withOpacity(color, 0.9)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLowStockReport(BuildContext context, List<ProductModel> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down, color: AppTheme.errorColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Düşük Stok Raporu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${products.length} ürün',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: AppTheme.successColor),
                          SizedBox(height: 16),
                          Text('Tüm stok seviyeleri yeterli!'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                              child: const Icon(Icons.warning, color: AppTheme.errorColor),
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                              'Stok: ${product.stock.toStringAsFixed(0)} / Min: ${product.minStock.toStringAsFixed(0)} ${product.unit}',
                            ),
                            trailing: Text(
                              '₺${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditSummary(BuildContext context, CreditProvider creditProvider) {
    final activeCredits = creditProvider.activeCredits;
    final overdueCredits = creditProvider.overdueCredits;
    final paidCredits = creditProvider.paidCredits;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Veresiye Özet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Aktif', activeCredits.length, AppTheme.warningColor),
                      _buildSummaryItem('Vadesi Geçen', overdueCredits.length, AppTheme.errorColor),
                      _buildSummaryItem('Ödenen', paidCredits.length, AppTheme.successColor),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOPLAM ALACAK',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₺${creditProvider.totalCreditAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  if (overdueCredits.isNotEmpty) ...[
                    const Text(
                      'Vadesi Geçenler',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor),
                    ),
                    const SizedBox(height: 8),
                    ...overdueCredits.map((credit) => _buildCreditListItem(credit, AppTheme.errorColor)),
                    const SizedBox(height: 16),
                  ],
                  if (activeCredits.isNotEmpty) ...[
                    const Text(
                      'Aktif Veresiyeler',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor),
                    ),
                    const SizedBox(height: 8),
                    ...activeCredits.map((credit) => _buildCreditListItem(credit, AppTheme.warningColor)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCreditListItem(CreditModel credit, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.person, color: color),
        ),
        title: Text(credit.customerFullName),
        subtitle: Text(credit.customerPhone),
        trailing: Text(
          '₺${credit.remainingAmount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showPopularProducts(BuildContext context, List<ProductModel> products) {
    // Şimdilik tüm ürünleri stok miktarına göre sırala
    final sortedProducts = List<ProductModel>.from(products)
      ..sort((a, b) => b.stock.compareTo(a.stock));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ürün Listesi (Stok Sıralı)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${products.length} ürün',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: sortedProducts.length,
                itemBuilder: (context, index) {
                  final product = sortedProducts[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.successColor.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('${product.category} • ${product.stock.toStringAsFixed(0)} ${product.unit}'),
                      trailing: Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlySummary(BuildContext context, ProductProvider productProvider, CreditProvider creditProvider) {
    final lowStockCount = productProvider.getLowStockProducts().length;
    final totalProducts = productProvider.products.length;
    final totalCreditAmount = creditProvider.totalCreditAmount;
    final activeCredits = creditProvider.activeCredits.length;
    final paidCredits = creditProvider.paidCredits.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  _getCurrentMonth(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stok Özeti
            _buildSummaryCard(
              title: 'Stok Durumu',
              icon: Icons.inventory,
              color: AppTheme.primaryColor,
              items: [
                SummaryItem('Toplam Ürün', totalProducts.toString()),
                SummaryItem('Düşük Stok', lowStockCount.toString()),
              ],
            ),
            const SizedBox(height: 16),

            // Veresiye Özeti
            _buildSummaryCard(
              title: 'Veresiye Durumu',
              icon: Icons.account_balance_wallet,
              color: AppTheme.warningColor,
              items: [
                SummaryItem('Toplam Alacak', '₺${totalCreditAmount.toStringAsFixed(2)}'),
                SummaryItem('Aktif Kayıt', activeCredits.toString()),
                SummaryItem('Ödenen Kayıt', paidCredits.toString()),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<SummaryItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label),
                  Text(
                    item.value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showSalesHistory(BuildContext context) {
    final salesProvider = context.read<SalesProvider>();
    final productProvider = context.read<ProductProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satış Geçmişi',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tüm ürün çıkışları',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Summary Cards
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMiniSummaryCard(
                        'Toplam Satış',
                        '${salesProvider.sales.length}',
                        Icons.shopping_cart,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniSummaryCard(
                        'Toplam Tutar',
                        '₺${salesProvider.totalSalesAmount.toStringAsFixed(2)}',
                        Icons.attach_money,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),

              // Sales List
              Expanded(
                child: salesProvider.sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz satış kaydı yok',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: salesProvider.sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sale = salesProvider.sales[index];
                          // Ürün barkodunu bul
                          final product = productProvider.products.firstWhere(
                            (p) => p.id == sale.productId,
                            orElse: () => ProductModel(
                              id: '',
                              name: sale.productName,
                              price: sale.unitPrice,
                              stock: 0,
                              minStock: 0,
                              unit: 'Adet',
                              category: '',
                              barcode: '',
                              sku: '',
                              brand: '',
                              description: '',
                              imageUrls: [],
                              isActive: true,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              createdBy: '',
                            ),
                          );
                          return _buildSaleCard(sale, product.barcode);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SalesModel sale, String barcode) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    
    Color saleTypeColor;
    String saleTypeText;
    IconData saleTypeIcon;
    
    switch (sale.saleType) {
      case 'credit':
        saleTypeColor = AppTheme.warningColor;
        saleTypeText = 'Veresiye';
        saleTypeIcon = Icons.credit_card;
        break;
      case 'card':
        saleTypeColor = AppTheme.primaryColor;
        saleTypeText = 'Kart';
        saleTypeIcon = Icons.payment;
        break;
      default:
        saleTypeColor = AppTheme.successColor;
        saleTypeText = 'Nakit';
        saleTypeIcon = Icons.payments;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün Adı ve Tarih
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(sale.saleDate),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: saleTypeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(saleTypeIcon, size: 14, color: saleTypeColor),
                    const SizedBox(width: 4),
                    Text(
                      saleTypeText,
                      style: TextStyle(
                        color: saleTypeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Barkod
          if (barcode.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    barcode,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Detaylar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSaleDetail('Miktar', '${sale.quantity.toStringAsFixed(0)}'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildSaleDetail('Birim Fiyat', '₺${sale.unitPrice.toStringAsFixed(2)}'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildSaleDetail('Toplam', '₺${sale.totalPrice.toStringAsFixed(2)}', isHighlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleDetail(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isHighlight ? 16 : 14,
            color: isHighlight ? AppTheme.successColor : Colors.black,
          ),
        ),
      ],
    );
  }
}

class SummaryItem {
  final String label;
  final String value;

  SummaryItem(this.label, this.value);
}
