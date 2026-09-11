import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/caretaker_application_model.dart';
import '../services/firebase_service.dart';

class CaretakerApplicationRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> create(CaretakerApplicationModel application) async {
    await _firebase.caretakerApplicationsCollection
        .doc(application.applicationId)
        .set(application.toMap());
  }

  Stream<List<CaretakerApplicationModel>> streamByCaretaker(String caretakerId) {
    return _firebase.caretakerApplicationsCollection
        .where('caretakerId', isEqualTo: caretakerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CaretakerApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<CaretakerApplicationModel>> streamByProperty(String propertyId) {
    return _firebase.caretakerApplicationsCollection
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CaretakerApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<CaretakerApplicationModel>> streamPendingForProperty(String propertyId) {
    return _firebase.caretakerApplicationsCollection
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CaretakerApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> update(String applicationId, Map<String, dynamic> data) async {
    await _firebase.caretakerApplicationsCollection.doc(applicationId).update(data);
  }

  Future<bool> hasPendingApplication(String caretakerId, String propertyId) async {
    final snapshot = await _firebase.caretakerApplicationsCollection
        .where('caretakerId', isEqualTo: caretakerId)
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.isNotEmpty;
  }
}

final caretakerApplicationRepositoryProvider = Provider<CaretakerApplicationRepository>((ref) {
  return CaretakerApplicationRepository();
});