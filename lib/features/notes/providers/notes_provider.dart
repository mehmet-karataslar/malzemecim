import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/note_model.dart';
import '../../../core/constants/app_constants.dart';

class NotesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Not sayısı
  int get noteCount => _notes.length;

  // Notları yükle
  Future<void> loadNotes() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection(AppConstants.notesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      _notes = snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Notlar yüklenirken hata oluştu: $e';
      print('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni not ekle
  Future<String> addNote({
    required String title,
    required String content,
    required int colorValue,
    required String createdBy,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final note = NoteModel(
        id: '', // Firestore tarafından atanacak
        title: title,
        content: content,
        createdAt: DateTime.now(),
        colorValue: colorValue,
        createdBy: createdBy,
        isActive: true,
      );

      final docRef = await _firestore
          .collection(AppConstants.notesCollection)
          .add(note.toFirestore());

      // Listeyi yeniden yükle
      await loadNotes();

      return docRef.id;
    } catch (e) {
      _errorMessage = 'Not eklenirken hata oluştu: $e';
      print('Error adding note: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Not güncelle
  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
    int? colorValue,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updateData = <String, dynamic>{
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (colorValue != null) {
        updateData['colorValue'] = colorValue;
      }

      await _firestore
          .collection(AppConstants.notesCollection)
          .doc(noteId)
          .update(updateData);

      // Listeyi yeniden yükle
      await loadNotes();
    } catch (e) {
      _errorMessage = 'Not güncellenirken hata oluştu: $e';
      print('Error updating note: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Not sil (soft delete)
  Future<void> deleteNote(String noteId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestore
          .collection(AppConstants.notesCollection)
          .doc(noteId)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Listeyi yeniden yükle
      await loadNotes();
    } catch (e) {
      _errorMessage = 'Not silinirken hata oluştu: $e';
      print('Error deleting note: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ID ile not bul
  NoteModel? getNoteById(String noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  // Notları ara
  List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return _notes;

    query = query.toLowerCase().trim();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();
  }

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
