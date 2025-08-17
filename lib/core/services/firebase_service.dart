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

  // Demo veriler için kullanılabilir
  static Future<void> createDemoData() async {
    try {
      // Demo admin kullanıcısı
      final adminEmail = 'admin@malzemecim.com';
      final employeeEmail = 'calisan@malzemecim.com';
      final password = '123456';

      // Admin kullanıcısı kontrolü
      final adminQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .get();

      if (adminQuery.docs.isEmpty) {
        // Admin kullanıcısı yoksa oluştur
        try {
          final adminCredential = await auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: password,
          );

          await firestore
              .collection('users')
              .doc(adminCredential.user!.uid)
              .set({
                'email': adminEmail,
                'name': 'Sistem Yöneticisi',
                'role': 'admin',
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });

          print('Demo admin user created');
        } catch (e) {
          print('Admin user might already exist: $e');
        }
      }

      // Employee kullanıcısı kontrolü
      final employeeQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: employeeEmail)
          .get();

      if (employeeQuery.docs.isEmpty) {
        try {
          final employeeCredential = await auth.createUserWithEmailAndPassword(
            email: employeeEmail,
            password: password,
          );

          await firestore
              .collection('users')
              .doc(employeeCredential.user!.uid)
              .set({
                'email': employeeEmail,
                'name': 'Mağaza Çalışanı',
                'role': 'employee',
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });

          print('Demo employee user created');
        } catch (e) {
          print('Employee user might already exist: $e');
        }
      }

      // Demo ürünler oluştur
      await _createDemoProducts();
    } catch (e) {
      print('Demo data creation error: $e');
    }
  }

  static Future<void> _createDemoProducts() async {
    try {
      final productsQuery = await firestore
          .collection('products')
          .limit(1)
          .get();
      if (productsQuery.docs.isNotEmpty) {
        print('Demo products already exist');
        return;
      }

      final demoProducts = [
        {
          'name': 'Vida M8x20',
          'brand': 'Koçtaş',
          'barcode': '1234567890123',
          'sku': 'VDA-M8-20',
          'description': 'Galvanizli vida M8x20mm',
          'price': 2.50,
          'unit': 'adet',
          'imageUrls': [],
          'category': 'Nalburiye',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
          'isActive': true,
        },
        {
          'name': 'Dış Cephe Boyası',
          'brand': 'Marshall',
          'barcode': '2345678901234',
          'sku': 'BYA-DC-15L',
          'description': 'Beyaz dış cephe boyası 15Lt',
          'price': 285.00,
          'unit': 'litre',
          'imageUrls': [],
          'category': 'Boya',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
          'isActive': true,
        },
        {
          'name': 'Elektrik Kablosu 2.5mm',
          'brand': 'Nexans',
          'barcode': '3456789012345',
          'sku': 'KBL-2.5MM',
          'description': 'NYA 2.5mm² elektrik kablosu',
          'price': 12.75,
          'unit': 'metre',
          'imageUrls': [],
          'category': 'Elektrik',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
          'isActive': true,
        },
      ];

      final batch = firestore.batch();

      for (final product in demoProducts) {
        final docRef = firestore.collection('products').doc();
        batch.set(docRef, product);

        // Stok bilgisi de ekle
        final inventoryRef = firestore.collection('inventory').doc(docRef.id);
        batch.set(inventoryRef, {
          'productId': docRef.id,
          'currentStock': 100.0,
          'minimumStock': 10.0,
          'maximumStock': 500.0,
          'location': 'Ana Depo',
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastUpdatedBy': 'system',
          'movements': [],
        });
      }

      await batch.commit();
      print('Demo products created successfully');
    } catch (e) {
      print('Demo products creation error: $e');
    }
  }
}
