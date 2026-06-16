import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document.dart';
import '../services/firestore_service.dart';

class DocumentProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Document> _documents = [];
  bool _isLoading = false;

  List<Document> get documents => _documents;
  bool get isLoading => _isLoading;

  Future<void> loadDocuments({
    int? propertyId,
    int? unitId,
    int? tenantId,
  }) async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('documents').get();
    _documents = snapshot.docs
        .map((doc) =>
            Document.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    if (propertyId != null || unitId != null || tenantId != null) {
      _documents = _documents.where((d) {
        if (propertyId != null && d.propertyId != propertyId) return false;
        if (unitId != null && d.unitId != unitId) return false;
        if (tenantId != null && d.tenantId != tenantId) return false;
        return true;
      }).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDocument(Document document) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('documents').doc(id.toString()).set(
      document.toFirestoreMap(),
    );
    await loadDocuments();
  }

  Future<void> deleteDocument(int id) async {
    await _firestore.db.collection('documents').doc(id.toString()).delete();
    await loadDocuments();
  }

  List<Document> getDocumentsByCategory(String category) {
    return _documents.where((d) => d.category == category).toList();
  }
}
