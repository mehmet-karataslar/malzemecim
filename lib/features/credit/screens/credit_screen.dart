import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/credit_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/credit_provider.dart';
import '../widgets/add_payment_dialog.dart';
import 'add_credit_screen.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  // Tab renkleri ve ikonları
  final List<_TabInfo> _tabs = [
    _TabInfo(
      label: 'Aktif',
      icon: Icons.hourglass_top,
      color: const Color(0xFF3B82F6), // Mavi
      gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    ),
    _TabInfo(
      label: 'Ödenen',
      icon: Icons.check_circle,
      color: const Color(0xFF10B981), // Yeşil
      gradient: const [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _TabInfo(
      label: 'Vadesi Geçen',
      icon: Icons.error,
      color: const Color(0xFFEF4444), // Kırmızı
      gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentIndex = _tabController.index);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreditProvider>().loadCredits();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<CreditProvider>(
        builder: (context, creditProvider, child) {
          return CustomScrollView(
            slivers: [
              // Custom App Bar with Gradient
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: _tabs[_currentIndex].color,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _tabs[_currentIndex].gradient,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Veresiye Defteri',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Müşteri borçlarını takip edin',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    if (authProvider.isAdmin) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.add, color: Colors.white),
                                          onPressed: _navigateToAddCredit,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Özet Kartları
                            Row(
                              children: [
                                _buildSummaryChip(
                                  icon: Icons.receipt_long,
                                  label: 'Toplam Alacak',
                                  value: '₺${creditProvider.totalCreditAmount.toStringAsFixed(0)}',
                                ),
                                const SizedBox(width: 12),
                                _buildSummaryChip(
                                  icon: Icons.people,
                                  label: 'Aktif Kayıt',
                                  value: '${creditProvider.activeCreditCount}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  child: Container(
                    color: Colors.white,
                    child: Padding(
                      // vertical padding azaltıldı
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: List.generate(_tabs.length, (index) {
                          final tab = _tabs[index];
                          final isSelected = _currentIndex == index;
                          final count = _getTabCount(creditProvider, index);
                          
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _tabController.animateTo(index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                // vertical padding biraz azaltıldı
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(colors: tab.gradient)
                                      : null,
                                  color: isSelected ? null : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: tab.color.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon boyutu biraz küçültüldü
                                    Icon(
                                      tab.icon,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                      size: 16,
                                    ),
                                    const SizedBox(height: 4),
                                    // Metin esnek yapıldı, tek satır ve taşma için ellipsis
                                    Flexible(
                                      child: Text(
                                        tab.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withOpacity(0.3) : tab.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          count.toString(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : tab.color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              if (creditProvider.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (creditProvider.errorMessage != null)
                SliverFillRemaining(
                  child: _buildErrorState(creditProvider),
                )
              else
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCreditList(creditProvider.activeCredits, 0),
                      _buildCreditList(creditProvider.paidCredits, 1),
                      _buildCreditList(creditProvider.overdueCredits, 2),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  int _getTabCount(CreditProvider provider, int index) {
    switch (index) {
      case 0:
        return provider.activeCredits.length;
      case 1:
        return provider.paidCredits.length;
      case 2:
        return provider.overdueCredits.length;
      default:
        return 0;
    }
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CreditProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          ),
          const SizedBox(height: 16),
          Text(provider.errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadCredits(),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddCredit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCreditScreen()),
    );
  }

  Widget _buildCreditList(List<CreditModel> credits, int tabIndex) {
    if (credits.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CreditProvider>().loadCredits(),
      color: _tabs[tabIndex].color,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: credits.length,
        itemBuilder: (context, index) {
          return _buildCreditCard(credits[index], tabIndex);
        },
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final tab = _tabs[tabIndex];
    final messages = [
      'Aktif veresiye kaydı yok',
      'Ödenmiş veresiye kaydı yok',
      'Vadesi geçen kayıt yok 🎉',
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tab.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(tab.icon, size: 48, color: tab.color),
          ),
          const SizedBox(height: 16),
          Text(
            messages[tabIndex],
            style: TextStyle(
              fontSize: 16,
              color: tab.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (tabIndex == 0)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isAdmin) {
                  return ElevatedButton.icon(
                    onPressed: _navigateToAddCredit,
                    icon: const Icon(Icons.add),
                    label: const Text('İlk Veresiyeyi Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tab.color,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

    Widget _buildCreditCard(CreditModel credit, int tabIndex) {
    final tab = _tabs[tabIndex];
    final progress = credit.totalAmount > 0
        ? credit.paidAmount / credit.totalAmount
        : 0.0;

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: tab.gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                credit.customerName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Başlıktaki uzun isimler için tek satır ve ellipsis eklendi
          title: Text(
            credit.customerFullName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  // Telefon numarası tek satır yapıldı
                  Expanded(
                    child: Text(
                      credit.customerPhone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tab.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₺${credit.remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tab.color,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '/ ₺${credit.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (tabIndex != 1) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(tab.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Tarih tek satır olarak sınırlandı
              Text(
                _formatDate(credit.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (credit.dueDate != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tabIndex == 2 ? AppTheme.errorColor.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Vade: ${_formatDate(credit.dueDate!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: tabIndex == 2 ? AppTheme.errorColor : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürünler
                  if (credit.items.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.shopping_basket, size: 16, color: tab.color),
                        const SizedBox(width: 8),
                        Text(
                          'Ürünler',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tab.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...credit.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: tab.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.productName)),
                          Text(
                            '${item.quantity.toStringAsFixed(0)} ${item.unit} x ₺${item.unitPrice.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )),
                    const Divider(height: 24),
                  ],

                  // Ödeme Geçmişi
                  if (credit.payments.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.history, size: 16, color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Ödeme Geçmişi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...credit.payments.map((payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getPaymentMethodIcon(payment.method),
                            size: 14,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₺${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(payment.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )),
                    const Divider(height: 24),
                  ],

                  // Notlar
                  if (credit.notes.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Not: ${credit.notes}',
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (!authProvider.isAdmin) return const SizedBox.shrink();

                      return Row(
                        children: [
                          if (tabIndex != 1) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showPaymentDialog(credit),
                                icon: const Icon(Icons.payment, size: 18),
                                label: const Text('Ödeme Al'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(credit),
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              label: const Text('Sil', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.account_balance;
      default:
        return Icons.payments;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _showPaymentDialog(CreditModel credit) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddPaymentDialog(
        maxAmount: credit.remainingAmount,
        customerName: credit.customerFullName,
      ),
    );

    if (result != null && mounted) {
      try {
        final authProvider = context.read<AuthProvider>();
        await context.read<CreditProvider>().addPayment(
          creditId: credit.id,
          amount: result['amount'] as double,
          method: result['method'] as String,
          notes: result['notes'] as String,
          receivedBy: authProvider.currentUser?.id ?? '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ödeme kaydedildi'),
              backgroundColor: AppTheme.successColor,
            ),
          );
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

  void _confirmDelete(CreditModel credit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: AppTheme.errorColor),
            ),
            const SizedBox(width: 12),
            const Text('Veresiyeyi Sil'),
          ],
        ),
        content: Text(
          '${credit.customerFullName} müşterisine ait veresiye kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<CreditProvider>().deleteCredit(credit.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veresiye kaydı silindi'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// Tab Bilgisi
class _TabInfo {
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  _TabInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

// Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  double get minExtent => 82.0;

  @override
  double get maxExtent => 82.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
