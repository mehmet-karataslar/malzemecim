import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/firebase_service.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/app_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'shared/widgets/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService.initialize();
    // Test kullanıcısı oluştur (geliştirme için)
    await FirebaseService.createTestUser();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const MalzemecimApp());
}

class MalzemecimApp extends StatelessWidget {
  const MalzemecimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Auth durumuna göre yönlendirme
            if (authProvider.isAuthenticated) {
              return const MainNavigation();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
