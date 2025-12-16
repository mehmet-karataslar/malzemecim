import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/appointment_provider.dart';
import '../../../../shared/models/appointment_model.dart';
import 'book_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    // İlk açılışta verileri dinlemeye başla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentProvider>(context, listen: false).listenToAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppointmentProvider>(context);
    final selectedDate = provider.selectedDate;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. Yatay Tarih Seçici (Header)
          _buildDateHeader(context, provider),
          
          // 2. Randevu Listesi
          Expanded(
            child: provider.isLoading && provider.appointments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildAppointmentList(provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
          );
        },
        label: const Text('Yeni Randevu'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, AppointmentProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              DateFormat('MMMM yyyy', 'tr_TR').format(provider.selectedDate),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 30, // 30 günlük takvim
              itemBuilder: (context, index) {
                final date = today.add(Duration(days: index - 2)); // 2 gün önceden başla
                final isSelected = date.year == provider.selectedDate.year &&
                                 date.month == provider.selectedDate.month &&
                                 date.day == provider.selectedDate.day;
                final isToday = date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;

                return GestureDetector(
                  onTap: () => provider.selectDate(date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : (isToday ? Colors.blue[50] : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : (isToday ? Colors.blue.withOpacity(0.3) : Colors.grey[300]!),
                        width: isSelected || isToday ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E', 'tr_TR').format(date), // Gün adı (Pzt, Sal)
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(AppointmentProvider provider) {
    final dailyAppointments = provider.getAppointmentsForDate(provider.selectedDate);

    if (dailyAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Bugün için randevu yok',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dailyAppointments.length,
      itemBuilder: (context, index) {
        final appointment = dailyAppointments[index];
        return _buildAppointmentCard(context, appointment, provider);
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appointment, AppointmentProvider provider) {
    // Rastgele renk veya duruma göre renk seçimi
    Color cardColor;
    Color textColor;
    
    switch (appointment.status) {
      case 'confirmed':
        cardColor = const Color(0xFFE3F2FD); // Light Blue
        textColor = const Color(0xFF1565C0);
        break;
      case 'completed':
        cardColor = const Color(0xFFE8F5E9); // Light Green
        textColor = const Color(0xFF2E7D32);
        break;
      case 'cancelled':
        cardColor = const Color(0xFFFFEBEE); // Light Red
        textColor = const Color(0xFFC62828);
        break;
      default:
        cardColor = Colors.white;
        textColor = Colors.black87;
    }

    return Dismissible(
      key: Key(appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Randevuyu Sil?'),
            content: const Text('Bu işlem geri alınamaz.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        provider.deleteAppointment(appointment.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu silindi')));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardColor == Colors.white ? Colors.grey[200]! : Colors.transparent),
        ),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            )
                          ]
                        ),
                        child: Icon(Icons.access_time, color: textColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('HH:mm').format(appointment.appointmentDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(appointment.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              appointment.customerPhone,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appointment.notes!,
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showStatusMenu(context, provider, appointment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label;
    Color color;
    
    switch (status) {
      case 'confirmed':
        label = 'Onaylı';
        color = Colors.blue;
        break;
      case 'completed':
        label = 'Tamamlandı';
        color = Colors.green;
        break;
      case 'cancelled':
        label = 'İptal';
        color = Colors.red;
        break;
      default:
        label = 'Bekliyor';
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusMenu(BuildContext context, AppointmentProvider provider, AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Tamamlandı Olarak İşaretle'),
            onTap: () {
              provider.updateStatus(appointment.id, 'completed');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('İptal Et'),
            onTap: () {
              provider.updateStatus(appointment.id, 'cancelled');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Beklemeye Al'),
            onTap: () {
              provider.updateStatus(appointment.id, 'pending');
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

