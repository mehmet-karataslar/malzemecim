import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veresiye Defteri'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddCreditDialog,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif', icon: Icon(Icons.schedule)),
            Tab(text: 'Ödenen', icon: Icon(Icons.check_circle)),
            Tab(text: 'Vadesi Geçen', icon: Icon(Icons.warning)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreditList('active'),
          _buildCreditList('paid'),
          _buildCreditList('overdue'),
        ],
      ),
    );
  }

  Widget _buildCreditList(String type) {
    // Mock data
    final mockCredits = [
      {
        'id': '1',
        'customerName': 'Ahmet Yılmaz',
        'phone': '0532 123 45 67',
        'amount': 1250.00,
        'paidAmount': type == 'paid' ? 1250.00 : 300.00,
        'remainingAmount': type == 'paid' ? 0.00 : 950.00,
        'date': '15.01.2025',
        'dueDate': '15.02.2025',
        'status': type,
        'items': 'Vida, Boya, Kablo',
      },
      {
        'id': '2',
        'customerName': 'Fatma Öz',
        'phone': '0541 987 65 43',
        'amount': 850.00,
        'paidAmount': type == 'paid' ? 850.00 : 0.00,
        'remainingAmount': type == 'paid' ? 0.00 : 850.00,
        'date': '10.01.2025',
        'dueDate': '10.02.2025',
        'status': type,
        'items': 'Dış Cephe Boyası',
      },
    ];

    final filteredCredits = mockCredits.where((credit) {
      if (type == 'active')
        return credit['remainingAmount'] as double > 0 &&
            credit['status'] != 'overdue';
      if (type == 'paid') return credit['remainingAmount'] as double <= 0;
      if (type == 'overdue') return credit['status'] == 'overdue';
      return true;
    }).toList();

    if (filteredCredits.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCredits.length,
      itemBuilder: (context, index) {
        return _buildCreditCard(filteredCredits[index], type);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;
    Color color;

    switch (type) {
      case 'active':
        message = 'Aktif veresiye kaydı bulunmuyor';
        icon = Icons.schedule;
        color = AppTheme.primaryColor;
        break;
      case 'paid':
        message = 'Ödenmiş veresiye kaydı bulunmuyor';
        icon = Icons.check_circle;
        color = AppTheme.successColor;
        break;
      case 'overdue':
        message = 'Vadesi geçen veresiye kaydı bulunmuyor';
        icon = Icons.warning;
        color = AppTheme.errorColor;
        break;
      default:
        message = 'Kayıt bulunmuyor';
        icon = Icons.info;
        color = AppTheme.textSecondary;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(Map<String, dynamic> credit, String type) {
    final remainingAmount = credit['remainingAmount'] as double;
    final totalAmount = credit['amount'] as double;
    final progress = totalAmount > 0
        ? (totalAmount - remainingAmount) / totalAmount
        : 0.0;

    Color statusColor;
    switch (type) {
      case 'paid':
        statusColor = AppTheme.successColor;
        break;
      case 'overdue':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.warningColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(type), color: statusColor),
        ),
        title: Text(
          credit['customerName'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(credit['phone']),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '₺${remainingAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 16,
                  ),
                ),
                Text(' / ₺${totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            if (type != 'paid') ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ],
          ],
        ),
        trailing: Text(
          credit['date'],
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Telefon', credit['phone']),
                _buildDetailRow('Alınan Ürünler', credit['items']),
                _buildDetailRow(
                  'Toplam Tutar',
                  '₺${totalAmount.toStringAsFixed(2)}',
                ),
                if (type != 'paid') ...[
                  _buildDetailRow(
                    'Ödenen',
                    '₺${(credit['paidAmount'] as double).toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Kalan',
                    '₺${remainingAmount.toStringAsFixed(2)}',
                  ),
                ],
                _buildDetailRow('Tarih', credit['date']),
                if (credit['dueDate'] != null)
                  _buildDetailRow('Vade Tarihi', credit['dueDate']),

                const SizedBox(height: 16),

                // Action Buttons
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (!authProvider.isAdmin) return const SizedBox.shrink();

                    return Row(
                      children: [
                        if (type != 'paid') ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showPaymentDialog(credit),
                              icon: const Icon(Icons.payment),
                              label: const Text('Ödeme Al'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreditDetails(credit),
                            icon: const Icon(Icons.visibility),
                            label: const Text('Detaylar'),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String type) {
    switch (type) {
      case 'paid':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.schedule;
    }
  }

  void _showAddCreditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Veresiye Kaydı'),
        content: const Text('Veresiye ekleme formu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> credit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Al'),
        content: const Text('Ödeme alma formu yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showCreditDetails(Map<String, dynamic> credit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${credit['customerName']} - Detaylar'),
        content: const Text('Detaylı veresiye bilgileri yakında gelecek...'),
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
