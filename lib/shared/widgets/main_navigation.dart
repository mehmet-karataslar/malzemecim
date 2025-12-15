import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../../features/scanner/screens/scanner_screen.dart';
import '../../features/products/screens/products_screen.dart';
import '../../features/credit/screens/credit_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AuthProvider>(
      builder: (context, appProvider, authProvider, child) {
        return Scaffold(
          body: _buildBody(appProvider.currentIndex, authProvider),
          bottomNavigationBar: _buildBottomNavigationBar(
            context,
            appProvider,
            authProvider,
          ),
          // Status mesajı göster
          floatingActionButton: appProvider.statusMessage != null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 80),
                  child: FloatingActionButton.extended(
                    onPressed: () => appProvider.clearStatusMessage(),
                    backgroundColor: appProvider.isOnline
                        ? Colors.green
                        : Colors.orange,
                    icon: Icon(
                      appProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: Colors.white,
                    ),
                    label: Text(
                      appProvider.statusMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(int currentIndex, AuthProvider authProvider) {
    switch (currentIndex) {
      case 0:
        return const ScannerScreen();
      case 1:
        return const ProductsScreen();
      case 2:
        return const CreditScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return const NotesScreen();
      case 5:
        return const AppointmentsScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const ScannerScreen();
    }
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    AppProvider appProvider,
    AuthProvider authProvider,
  ) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner),
        label: 'Tara',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory),
        label: 'Ürünler',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet),
        label: 'Veresiye',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assessment),
        label: 'Raporlar',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notlar'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Randevular',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Ayarlar',
      ),
    ];

    // Çalışan ise sadece belirli sekmeler göster
    if (authProvider.isEmployee) {
      items = [
        items[0], // Tara
        items[1], // Ürünler (sadece görüntüleme)
        items[6], // Ayarlar
      ];
    }

    return BottomNavigationBar(
      currentIndex: appProvider.currentIndex >= items.length
          ? 0
          : appProvider.currentIndex,
      onTap: (index) {
        // Çalışan ise index mapping
        if (authProvider.isEmployee) {
          switch (index) {
            case 0: // Tara
              appProvider.setCurrentIndex(0);
              break;
            case 1: // Ürünler
              appProvider.setCurrentIndex(1);
              break;
            case 2: // Ayarlar
              appProvider.setCurrentIndex(6);
              break;
          }
        } else {
          appProvider.setCurrentIndex(index);
        }
      },
      items: items,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 10,
    );
  }
}
