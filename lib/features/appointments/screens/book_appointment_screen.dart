import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/appointment_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBusinessId;
  String? _selectedBusinessName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<UserModel> _businesses = [];
  bool _isLoadingBusinesses = true;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _businesses = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.businessName != null && user.businessName!.isNotEmpty)
            .toList();
        _isLoadingBusinesses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBusinesses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşletmeler yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBusinessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir işletme seçiniz')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçiniz')),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (appointmentDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçmiş bir tarih seçemezsiniz')),
      );
      return;
    }

    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);

    final success = await appointmentProvider.createAppointment(
      businessId: _selectedBusinessId!,
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      appointmentDate: appointmentDateTime,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Randevu bilgilerini göster
        _showSuccessDialog(appointmentDateTime);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentProvider.errorMessage ?? 'Randevu oluşturulamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Al'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // İşletme Seçimi
              _buildBusinessSelector(),

              const SizedBox(height: 24),

              // Müşteri Bilgileri
              _buildSectionTitle('Müşteri Bilgileri'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad gereklidir';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Telefon numarası gereklidir';
                  }
                  if (value.trim().length < 10) {
                    return 'Geçerli bir telefon numarası giriniz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Opsiyonel)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Geçerli bir email adresi giriniz';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Randevu Tarihi ve Saati
              _buildSectionTitle('Randevu Tarihi ve Saati'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Tarih Seç'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Saat Seç'
                            : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notlar
              _buildSectionTitle('Notlar (Opsiyonel)'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ek notlar',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Gönder Butonu
              Consumer<AppointmentProvider>(
                builder: (context, appointmentProvider, child) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: appointmentProvider.isLoading ? null : _submitAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: appointmentProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Randevu Oluştur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1e3a8a),
      ),
    );
  }

  Widget _buildBusinessSelector() {
    if (_isLoadingBusinesses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_businesses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text('Henüz kayıtlı işletme bulunmamaktadır'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('İşletme Seçimi *'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedBusinessId,
          decoration: const InputDecoration(
            labelText: 'İşletme',
            prefixIcon: Icon(Icons.business),
          ),
          items: _businesses.map((business) {
            return DropdownMenuItem<String>(
              value: business.id,
              child: Text(business.businessName ?? business.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBusinessId = value;
              _selectedBusinessName = _businesses
                  .firstWhere((b) => b.id == value)
                  .businessName;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Lütfen bir işletme seçiniz';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _showSuccessDialog(DateTime appointmentDateTime) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final timeFormat = DateFormat('HH:mm', 'tr_TR');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başarı İkonu
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                const Text(
                  'Randevunuz Gönderildi!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Randevu bilgileriniz işletmeye iletildi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Randevu Bilgileri
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.business,
                        'İşletme',
                        _selectedBusinessName ?? 'Seçilen İşletme',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.person,
                        'Ad Soyad',
                        _nameController.text.trim(),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.phone,
                        'Telefon',
                        _phoneController.text.trim(),
                      ),
                      if (_emailController.text.trim().isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.email,
                          'Email',
                          _emailController.text.trim(),
                        ),
                      ],
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Tarih',
                        dateFormat.format(appointmentDateTime),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.access_time,
                        'Saat',
                        timeFormat.format(appointmentDateTime),
                      ),
                      if (_notesController.text.trim().isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.note,
                          'Notlar',
                          _notesController.text.trim(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bilgi Mesajı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'İşletme randevunuzu onayladığında size bilgi verilecektir.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tamam Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Formu temizle
                      _nameController.clear();
                      _phoneController.clear();
                      _emailController.clear();
                      _notesController.clear();
                      setState(() {
                        _selectedBusinessId = null;
                        _selectedBusinessName = null;
                        _selectedDate = null;
                        _selectedTime = null;
                      });
                      Navigator.of(context).pop(); // Dialog'u kapat
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

