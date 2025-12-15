import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == AppConstants.adminRole;
  bool get isEmployee => _currentUser?.role == AppConstants.employeeRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constructor
  AuthProvider() {
    _checkAuthState();
  }

  // Auth durumunu kontrol et
  void _checkAuthState() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Kullanıcı verilerini yükle
  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Kullanıcı bilgileri yüklenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  // Kayıt ol
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String businessName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Firebase Auth'da kullanıcı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Firestore'da kullanıcı profili oluştur
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'name': name,
          'businessName': businessName,
          'role': 'admin', // İlk kayıt olan kullanıcı admin olur
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Kullanıcı verilerini yükle
        await _loadUserData(result.user!.uid);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Kayıt işlemi sırasında hata oluştu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email ile giriş
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _updateLastLogin(result.user!.uid);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Giriş yapılırken hata oluştu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Son giriş zamanını güncelle
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'lastLoginAt': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      // Silent fail, critical değil
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Çıkış yapılırken hata oluştu: $e';
      notifyListeners();
    }
  }

  // Auth hatalarını işle
  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _errorMessage = 'Bu email adresi ile kayıtlı kullanıcı bulunamadı.';
        break;
      case 'wrong-password':
        _errorMessage = 'Hatalı şifre girdiniz.';
        break;
      case 'email-already-in-use':
        _errorMessage = 'Bu email adresi zaten kullanımda.';
        break;
      case 'weak-password':
        _errorMessage = 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
        break;
      case 'invalid-email':
        _errorMessage = 'Geçersiz email adresi.';
        break;
      case 'too-many-requests':
        _errorMessage =
            'Çok fazla hatalı deneme. Lütfen daha sonra tekrar deneyin.';
        break;
      default:
        _errorMessage = 'Bir hata oluştu: ${e.message}';
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Şifre güncelle
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'Kullanıcı bulunamadı';
        return false;
      }

      // Mevcut şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi güncelle
      await user.updatePassword(newPassword);

      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Şifre güncellenirken hata oluştu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // E-posta değiştir
  Future<bool> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'Kullanıcı bulunamadı';
        return false;
      }

      // Mevcut şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // E-postayı Firebase Auth'da güncelle
      await user.updateEmail(newEmail);
      
      // Kullanıcı bilgilerini yeniden yükle (e-posta güncellemesini yansıtmak için)
      await user.reload();
      
      // Güncellenmiş kullanıcı bilgilerini al
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) {
        _errorMessage = 'Kullanıcı bilgileri yüklenemedi';
        return false;
      }

      // Firestore'da e-postayı güncelle
      await _firestore.collection(AppConstants.usersCollection).doc(updatedUser.uid).update({
        'email': newEmail,
      });

      // Kullanıcı verilerini yeniden yükle
      await _loadUserData(updatedUser.uid);

      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'E-posta güncellenirken hata oluştu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Profil bilgilerini güncelle
  Future<bool> updateProfile({
    String? name,
    String? businessName,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _errorMessage = 'Kullanıcı bulunamadı';
        return false;
      }

      // Firestore'da güncelleme yapılacak alanları hazırla
      final updateData = <String, dynamic>{};
      if (name != null && name.isNotEmpty) {
        updateData['name'] = name;
      }
      if (businessName != null) {
        updateData['businessName'] = businessName.isEmpty ? null : businessName;
      }
      if (phone != null) {
        updateData['phone'] = phone.isEmpty ? null : phone;
      }

      if (updateData.isEmpty) {
        _errorMessage = 'Güncellenecek bilgi bulunamadı';
        return false;
      }

      // Firestore'da güncelle
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update(updateData);

      // Kullanıcı verilerini yeniden yükle
      await _loadUserData(user.uid);

      return true;
    } catch (e) {
      _errorMessage = 'Profil güncellenirken hata oluştu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
