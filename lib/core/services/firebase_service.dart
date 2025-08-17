import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Firestore settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true, // Offline desteği
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      print('Firebase initialized successfully for malzemecim-21');
    } catch (e) {
      print('Firebase initialization error: $e');
      rethrow;
    }
  }

  // Test kullanıcısı oluşturma (geliştirme için)
  static Future<void> createTestUser() async {
    try {
      final testEmail = 'hakim@gmail.com';
      final testPassword = 'dicle2121';

      // Kullanıcı zaten var mı kontrol et
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: testEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        // Test kullanıcısı oluştur
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Firestore'a kullanıcı bilgilerini kaydet
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': testEmail,
          'name': 'Hakim Bey',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        print('Test user created successfully: $testEmail');
      } else {
        print('Test user already exists: $testEmail');
      }
    } catch (e) {
      print('Test user creation error: $e');
    }
  }
}
