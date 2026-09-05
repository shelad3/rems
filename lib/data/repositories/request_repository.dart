import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/access_request_model.dart';
import '../services/firebase_service.dart';

class RequestRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> createRequest(AccessRequestModel request) async {
    await _firebase.accessRequestsCollection.doc(request.requestId).set(request.toMap());
  }

  Stream<List<AccessRequestModel>> getRequestsByTenant(String tenantId) {
    return _firebase.accessRequestsCollection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<AccessRequestModel>> getRequestsByProperty(String propertyId, {String? status}) {
    Query query = _firebase.accessRequestsCollection
        .where('propertyId', isEqualTo: propertyId);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.orderBy('requestedAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AccessRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> updateRequest(String requestId, Map<String, dynamic> data) async {
    await _firebase.accessRequestsCollection.doc(requestId).update(data);
  }

  Stream<List<AccessRequestModel>> getPendingRequestsByProperty(String propertyId) {
    return _firebase.accessRequestsCollection
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<AccessRequestModel>> getAllPendingRequests() {
    return _firebase.accessRequestsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccessRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository();
});
