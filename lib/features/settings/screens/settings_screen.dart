import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lowStockNotifications = true;
  bool _paymentReminders = true;
  bool _offlineSync = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _lowStockNotifications = prefs.getBool('low_stock_notifications') ?? true;
        _paymentReminders = prefs.getBool('payment_reminders') ?? true;
        _offlineSync = prefs.getBool('offline_sync') ?? true;
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Info Card
              _buildUserInfoCard(authProvider),

              const SizedBox(height: 24),

              // Uygulama Ayarları
              _buildSettingsSection(
                context,
                title: 'Uygulama',
                children: [
                  _buildSwitchTile(
                    icon: Icons.cloud_sync,
                    title: 'Offline Senkronizasyon',
                    subtitle: 'Verileri otomatik senkronize et',
                    value: _offlineSync,
                    onChanged: (value) {
                      setState(() => _offlineSync = value);
                      _saveSetting('offline_sync', value);
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.scanner,
                    title: 'Barkod Ayarları',
                    subtitle: 'Tarayıcı konfigürasyonu',
                    onTap: () => _showBarcodeSettings(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bildirim Ayarları
              _buildSettingsSection(
                context,
                title: 'Bildirimler',
                children: [
                  _buildSwitchTile(
                    icon: Icons.inventory_2,
                    title: 'Düşük Stok Uyarıları',
                    subtitle: 'Stok azaldığında bildirim al',
                    value: _lowStockNotifications,
                    onChanged: (value) {
                      setState(() => _lowStockNotifications = value);
                      _saveSetting('low_stock_notifications', value);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.payment,
                    title: 'Ödeme Hatırlatmaları',
                    subtitle: 'Veresiye vade tarihleri için hatırlatma',
                    value: _paymentReminders,
                    onChanged: (value) {
                      setState(() => _paymentReminders = value);
                      _saveSetting('payment_reminders', value);
                    },
                  ),
                ],
              ),

              if (authProvider.isAdmin) ...[
                const SizedBox(height: 24),
                _buildSettingsSection(
                  context,
                  title: 'Yönetim',
                  children: [
                    _buildSettingsTile(
                      icon: Icons.people,
                      title: 'Kullanıcı Yönetimi',
                      subtitle: 'Çalışan hesapları yönet',
                      onTap: () => _showUserManagement(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.backup,
                      title: 'Veri Yedekleme',
                      subtitle: 'Verileri yedekle ve geri yükle',
                      onTap: () => _showBackupOptions(context),
                    ),
                    _buildSettingsTile(
                      icon: Icons.security,
                      title: 'Güvenlik',
                      subtitle: 'Şifre değiştirme',
                      onTap: () => _showSecuritySettings(context, authProvider),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              _buildSettingsSection(
                context,
                title: 'Hakkında',
                children: [
                  _buildSettingsTile(
                    icon: Icons.info,
                    title: 'Uygulama Bilgisi',
                    subtitle: 'Sürüm ${AppConstants.appVersion}',
                    onTap: () => _showAppInfo(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.help,
                    title: 'Yardım & Destek',
                    subtitle: 'Kullanım kılavuzu ve iletişim',
                    onTap: () => _showHelp(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showLogoutConfirmation(context, authProvider),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(user.email, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? AppTheme.primaryColor
                          : AppTheme.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isAdmin ? 'Yönetici' : 'Çalışan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfile(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showBarcodeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.scanner, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Barkod Ayarları'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Otomatik Tanıma'),
              subtitle: const Text('Barkod formatını otomatik algıla'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            ListTile(
              title: const Text('Sesli Uyarı'),
              subtitle: const Text('Tarama sonrası ses çal'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            ListTile(
              title: const Text('Titreşim'),
              subtitle: const Text('Tarama sonrası titret'),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
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

  void _showUserManagement(BuildContext context) {
    // TODO: Implement full user management screen
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.people, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Kullanıcı Yönetimi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Bu bölümde işletmenize çalışan ekleyebilir ve yönetebilirsiniz.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.successColor,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: const Text('Yeni Çalışan Ekle'),
                subtitle: const Text('Email ile davet gönder'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Çalışan ekleme özelliği yakında eklenecek'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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

  void _showBackupOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.backup, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Veri Yedekleme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: AppTheme.primaryColor),
              title: const Text('Yedekle'),
              subtitle: const Text('Verileri buluta yedekle'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Veriler Firebase\'e otomatik olarak yedekleniyor'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download, color: AppTheme.warningColor),
              title: const Text('Geri Yükle'),
              subtitle: const Text('Yedekten verileri geri yükle'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Veriler Firebase\'den otomatik olarak senkronize ediliyor'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
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

  void _showSecuritySettings(BuildContext context, AuthProvider authProvider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.security, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Şifre Değiştir'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifreler eşleşmiyor'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifre en az 6 karakter olmalı'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Şifre değiştirme özelliği yakında eklenecek'),
                ),
              );
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profili Düzenle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Profil güncelleme özelliği yakında eklenecek'),
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(AppConstants.appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Sürüm', AppConstants.appVersion),
            _buildInfoRow('Platform', 'Flutter'),
            _buildInfoRow('Veritabanı', 'Firebase Firestore'),
            const SizedBox(height: 16),
            const Text(
              'Nalbur, hırdavat ve boya satış işletmeleri için geliştirilmiş envanter ve veresiye yönetim sistemi.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.help, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Yardım & Destek',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildHelpItem(
              icon: Icons.book,
              title: 'Kullanım Kılavuzu',
              subtitle: 'Uygulama özelliklerini öğrenin',
            ),
            _buildHelpItem(
              icon: Icons.video_library,
              title: 'Video Eğitimler',
              subtitle: 'Adım adım video anlatımlar',
            ),
            _buildHelpItem(
              icon: Icons.email,
              title: 'İletişim',
              subtitle: 'destek@malzemecim.com',
            ),
            _buildHelpItem(
              icon: Icons.bug_report,
              title: 'Hata Bildir',
              subtitle: 'Sorunları bize bildirin',
            ),
            const SizedBox(height: 16),
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

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(content: Text('$title yakında eklenecek')),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Uygulamadan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authProvider.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
