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

  // Yeni kullanıcı kaydı (sadece admin yapabilir)
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        UserModel newUser = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(result.user!.uid)
            .set(newUser.toFirestore());

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Kullanıcı kaydı oluşturulurken hata oluştu: $e';
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
}
