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
}
