import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class AddPaymentDialog extends StatefulWidget {
  final double maxAmount;
  final String customerName;

  const AddPaymentDialog({
    super.key,
    required this.maxAmount,
    required this.customerName,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'cash';

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'Nakit', 'icon': Icons.money},
    {'value': 'card', 'label': 'Kredi Kartı', 'icon': Icons.credit_card},
    {'value': 'transfer', 'label': 'Havale/EFT', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.maxAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.payment, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          const Expanded(child: Text('Ödeme Al')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Müşteri Adı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kalan Tutar
              Text(
                'Kalan Borç: ₺${widget.maxAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Ödeme Tutarı
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Ödeme Tutarı *',
                  prefixText: '₺ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tutar gerekli';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Geçerli bir tutar girin';
                  }
                  if (amount > widget.maxAmount) {
                    return 'Tutar kalan borçtan fazla olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Hızlı Tutar Butonları
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickAmountButton(widget.maxAmount),
                  if (widget.maxAmount > 100)
                    _buildQuickAmountButton(100),
                  if (widget.maxAmount > 500)
                    _buildQuickAmountButton(500),
                ],
              ),
              const SizedBox(height: 16),

              // Ödeme Yöntemi
              const Text(
                'Ödeme Yöntemi',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _paymentMethods.map((method) {
                  final isSelected = _selectedMethod == method['value'];
                  return ChoiceChip(
                    avatar: Icon(
                      method['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    label: Text(method['label'] as String),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMethod = method['value'] as String);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notlar
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  hintText: 'Ödeme ile ilgili not...',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _submitPayment,
          icon: const Icon(Icons.check),
          label: const Text('Ödemeyi Kaydet'),
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    return ActionChip(
      label: Text('₺${amount.toStringAsFixed(0)}'),
      onPressed: () {
        _amountController.text = amount.toStringAsFixed(2);
      },
    );
  }

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      Navigator.pop(context, {
        'amount': amount,
        'method': _selectedMethod,
        'notes': _notesController.text.trim(),
      });
    }
  }
}
