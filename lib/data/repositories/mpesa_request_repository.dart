import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mpesa_request_model.dart';
import '../services/firebase_service.dart';

class MpesaRequestRepository {
  final FirebaseService _firebase = FirebaseService();

  CollectionReference get _collection => _firebase.firestore.collection('mpesa_requests');

  Future<void> createRequest(MpesaRequestModel request) async {
    await _collection.doc(request.checkoutRequestId).set(request.toMap());
  }

  Future<MpesaRequestModel?> getRequest(String checkoutRequestId) async {
    final doc = await _collection.doc(checkoutRequestId).get();
    if (!doc.exists) return null;
    return MpesaRequestModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<MpesaRequestModel?> streamRequest(String checkoutRequestId) {
    return _collection
        .doc(checkoutRequestId)
        .snapshots()
        .map((doc) =>
            doc.exists
                ? MpesaRequestModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id)
                : null);
  }
}

final mpesaRequestRepositoryProvider = Provider<MpesaRequestRepository>((ref) {
  return MpesaRequestRepository();
});