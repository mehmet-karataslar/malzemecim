import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

              // Settings Sections
              _buildSettingsSection(
                context,
                title: 'Uygulama',
                children: [
                  _buildSettingsTile(
                    icon: Icons.cloud_sync,
                    title: 'Offline Senkronizasyon',
                    subtitle: 'Verileri otomatik senkronize et',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement offline sync toggle
                      },
                    ),
                  ),
                  _buildSettingsTile(
                    icon: Icons.scanner,
                    title: 'Barkod Ayarları',
                    subtitle: 'Tarayıcı konfigürasyonu',
                    onTap: () => _showBarcodeSettings(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'Bildirimler',
                    subtitle: 'Düşük stok ve ödeme hatırlatmaları',
                    onTap: () => _showNotificationSettings(context),
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
                      subtitle: 'Şifre ve güvenlik ayarları',
                      onTap: () => _showSecuritySettings(context),
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
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null),
      onTap: onTap,
    );
  }

  void _showBarcodeSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barkod Ayarları'),
        content: const Text('Barkod tarayıcı ayarları yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Ayarları'),
        content: const Text('Bildirim ayarları yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showUserManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Yönetimi'),
        content: const Text('Kullanıcı yönetimi yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veri Yedekleme'),
        content: const Text('Yedekleme seçenekleri yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Ayarları'),
        content: const Text('Güvenlik ayarları yakında gelecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppConstants.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sürüm: ${AppConstants.appVersion}'),
            const SizedBox(height: 8),
            const Text('Envanter ve Veresiye Yönetim Sistemi'),
            const SizedBox(height: 8),
            const Text(
              'Nalbur, hırdavat ve boya satış işletmeleri için geliştirilmiştir.',
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

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım & Destek'),
        content: const Text(
          'Yardım dokümanları ve iletişim bilgileri yakında gelecek...',
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

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Uygulamadan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
