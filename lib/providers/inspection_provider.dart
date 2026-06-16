import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inspection.dart';
import '../services/firestore_service.dart';

class InspectionProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Inspection> _inspections = [];
  List<InspectionItem> _inspectionItems = [];
  bool _isLoading = false;

  List<Inspection> get inspections => _inspections;
  List<InspectionItem> get inspectionItems => _inspectionItems;
  bool get isLoading => _isLoading;

  Future<void> loadInspectionsByProperty(int propertyId) async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db
        .collection('inspections')
        .where('propertyId', isEqualTo: propertyId)
        .get();
    _inspections = snapshot.docs
        .map((doc) => Inspection.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInspectionItems(int inspectionId) async {
    final snapshot = await _firestore.db
        .collection('inspection_items')
        .where('inspectionId', isEqualTo: inspectionId)
        .get();
    _inspectionItems = snapshot.docs
        .map((doc) => InspectionItem.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    notifyListeners();
  }

  Future<int> addInspection(Inspection inspection) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('inspections').doc(id.toString()).set(
      inspection.toFirestoreMap(),
    );
    await loadInspectionsByProperty(inspection.propertyId);
    return id;
  }

  Future<void> updateInspection(Inspection inspection) async {
    await _firestore.db
        .collection('inspections')
        .doc(inspection.id!.toString())
        .update(inspection.toFirestoreMap());
    await loadInspectionsByProperty(inspection.propertyId);
  }

  Future<void> deleteInspection(int id, int propertyId) async {
    await _firestore.db.collection('inspections').doc(id.toString()).delete();
    await loadInspectionsByProperty(propertyId);
  }

  Future<void> addInspectionItem(InspectionItem item) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('inspection_items').doc(id.toString()).set(
      item.toFirestoreMap(),
    );
    await loadInspectionItems(item.inspectionId);
  }

  Future<void> deleteInspectionItem(int id, int inspectionId) async {
    await _firestore.db
        .collection('inspection_items')
        .doc(id.toString())
        .delete();
    await loadInspectionItems(inspectionId);
  }
}
