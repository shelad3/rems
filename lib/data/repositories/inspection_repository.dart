import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inspection_model.dart';
import '../services/firebase_service.dart';

class InspectionRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> createInspection(InspectionModel inspection) async {
    await _firebase.firestore
        .collection('inspections')
        .doc(inspection.inspectionId)
        .set(inspection.toMap());
  }

  Stream<List<InspectionModel>> getInspectionsByUnit(String unitId) {
    return _firebase.firestore
        .collection('inspections')
        .where('unitId', isEqualTo: unitId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InspectionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<InspectionModel>> getInspectionsByProperty(String propertyId) {
    return _firebase.firestore
        .collection('inspections')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InspectionModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepository();
});
