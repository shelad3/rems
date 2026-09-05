import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lease_model.dart';
import '../services/firebase_service.dart';

class LeaseRepository {
  final FirebaseService _firebase = FirebaseService();

  Stream<List<LeaseModel>> getLeasesByTenant(String tenantId) {
    return _firebase.leasesCollection
        .where('tenantId', isEqualTo: tenantId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<LeaseModel>> getLeasesByProperty(String propertyId) {
    return _firebase.leasesCollection
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateLeaseStatus(String leaseId, String status) async {
    await _firebase.leasesCollection.doc(leaseId).update({'status': status});
  }

  Future<void> acceptLeaseTerms(String leaseId) async {
    await _firebase.leasesCollection.doc(leaseId).update({'termsAccepted': true});
  }
}

final leaseRepositoryProvider = Provider<LeaseRepository>((ref) {
  return LeaseRepository();
});
