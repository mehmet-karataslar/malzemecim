import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Helper to create a color with opacity without using deprecated getters
Color _withOpacity(Color color, double opacity) {
  final int a = (opacity * 255).round() & 0xFF;
  return Color((a << 24) | (color.toARGB32() & 0x00FFFFFF));
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (ctx) {
            final items = [
              {
                'title': 'Düşük Stok',
                'icon': Icons.trending_down,
                'color': AppTheme.errorColor,
                'subtitle': '5 ürün',
                'onTap': () => _showLowStockReport(ctx),
              },
              {
                'title': 'Veresiye Toplam',
                'icon': Icons.account_balance_wallet,
                'color': AppTheme.warningColor,
                'subtitle': '₺3,450',
                'onTap': () => _showCreditSummary(ctx),
              },
              {
                'title': 'En Çok Aranan',
                'icon': Icons.trending_up,
                'color': AppTheme.successColor,
                'subtitle': '25 ürün',
                'onTap': () => _showPopularProducts(ctx),
              },
              {
                'title': 'Aylık Özet',
                'icon': Icons.calendar_month,
                'color': AppTheme.primaryColor,
                'subtitle': 'Ocak 2025',
                'onTap': () => _showMonthlySummary(ctx),
              },
            ];

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final it = items[index];
                return _buildReportCard(
                  ctx,
                  title: it['title'] as String,
                  icon: it['icon'] as IconData,
                  color: it['color'] as Color,
                  subtitle: it['subtitle'] as String,
                  onTap: it['onTap'] as VoidCallback,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // Modern, colorful report card with gradient background and soft shadow
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
                  // Colored circular icon with its own gradient
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

                  // Title / subtitle column
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

                  // Chevron
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

  void _showLowStockReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Düşük Stok Raporu'),
        content: const Text('Düşük stok raporu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showCreditSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veresiye Özet'),
        content: const Text('Veresiye özet raporu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showPopularProducts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('En Çok Aranan Ürünler'),
        content: const Text('Popüler ürünler raporu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showMonthlySummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aylık Özet'),
        content: const Text('Aylık özet raporu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
