import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/appointment_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.currentUser != null) {
        Provider.of<AppointmentProvider>(context, listen: false)
            .loadBusinessAppointments(authProvider.currentUser!.id);
      }
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
      appBar: AppBar(
        title: const Text('Randevular'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bekleyen', icon: Icon(Icons.pending)),
            Tab(text: 'Onaylanan', icon: Icon(Icons.check_circle)),
            Tab(text: 'Tamamlanan', icon: Icon(Icons.done_all)),
          ],
        ),
      ),
      body: Consumer2<AppointmentProvider, AuthProvider>(
        builder: (context, appointmentProvider, authProvider, child) {
          if (appointmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appointmentProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    appointmentProvider.errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsList(
                appointmentProvider.getPendingAppointments(),
                'pending',
                appointmentProvider,
              ),
              _buildAppointmentsList(
                appointmentProvider.getConfirmedAppointments(),
                'confirmed',
                appointmentProvider,
              ),
              _buildAppointmentsList(
                appointmentProvider.getCompletedAppointments(),
                'completed',
                appointmentProvider,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<AppointmentModel> appointments,
    String status,
    AppointmentProvider appointmentProvider,
  ) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Randevu bulunmamaktadır',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.currentUser != null) {
          await appointmentProvider.loadBusinessAppointments(authProvider.currentUser!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment, appointmentProvider);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment,
    AppointmentProvider appointmentProvider,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isPast = appointment.appointmentDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: _buildStatusIcon(appointment.status),
        title: Text(
          appointment.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 ${dateFormat.format(appointment.appointmentDate)}'),
            Text('📞 ${appointment.customerPhone}'),
            if (appointment.customerEmail != null)
              Text('📧 ${appointment.customerEmail}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointment.notes != null && appointment.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Notlar: ${appointment.notes}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (appointment.isPending) ...[
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(
                          appointment.id,
                          'confirmed',
                          appointmentProvider,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(
                          appointment.id,
                          'cancelled',
                          appointmentProvider,
                        ),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('İptal Et'),
                      ),
                    ],
                    if (appointment.isConfirmed && !isPast) ...[
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(
                          appointment.id,
                          'completed',
                          appointmentProvider,
                        ),
                        icon: const Icon(Icons.done, size: 18),
                        label: const Text('Tamamla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                    if (appointment.isPending || appointment.isConfirmed)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAppointment(
                          appointment.id,
                          appointmentProvider,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.pending, color: Colors.orange);
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'completed':
        return const Icon(Icons.done_all, color: Colors.blue);
      default:
        return const Icon(Icons.event);
    }
  }

  Future<void> _updateStatus(
    String appointmentId,
    String newStatus,
    AppointmentProvider appointmentProvider,
  ) async {
    final success = await appointmentProvider.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu durumu güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appointmentProvider.errorMessage ?? 'Güncelleme başarısız',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAppointment(
    String appointmentId,
    AppointmentProvider appointmentProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevuyu Sil'),
        content: const Text('Bu randevuyu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await appointmentProvider.deleteAppointment(appointmentId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevu silindi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appointmentProvider.errorMessage ?? 'Silme başarısız',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

