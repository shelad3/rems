import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lease_model.dart';
import '../models/unit_model.dart';
import '../models/access_request_model.dart';
import '../services/firebase_service.dart';

class LeaseRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> create(LeaseModel lease) async {
    await _firebase.leasesCollection.doc(lease.leaseId).set(lease.toMap());
  }

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

  /// Transactional approve: creates lease, occupies unit, decrements available, flips access request.
  Future<void> approveRequest({
    required AccessRequestModel request,
    required String reviewedBy,
  }) async {
    await _firebase.firestore.runTransaction((txn) async {
      final reqRef = _firebase.accessRequestsCollection.doc(request.requestId);
      final propRef = _firebase.propertiesCollection.doc(request.propertyId);

      final propSnap = await txn.get(propRef);
      if (!propSnap.exists) throw Exception('Property not found');
      final propData = propSnap.data()! as Map<String, dynamic>;
      final availableUnits = (propData['availableUnits'] ?? 0) as int;

      double rentAmount = 0;
      double depositAmount = 0;
      UnitModel? unit;

      if (request.unitId != null && request.unitId!.isNotEmpty) {
        final unitRef = _firebase.unitsCollection.doc(request.unitId!);
        final unitSnap = await txn.get(unitRef);
        if (unitSnap.exists) {
          unit = UnitModel.fromMap(unitSnap.data()! as Map<String, dynamic>, unitSnap.id);
          rentAmount = unit.rentAmount;
          depositAmount = unit.depositAmount;
        }
      }

      final moveIn = request.desiredMoveInDate != null
          ? DateTime.tryParse(request.desiredMoveInDate!) ?? DateTime.now()
          : DateTime.now();

      final leaseId = _firebase.leasesCollection.doc().id;
      final lease = LeaseModel(
        leaseId: leaseId,
        tenantId: request.tenantId,
        propertyId: request.propertyId,
        unitId: request.unitId ?? '',
        startDate: moveIn,
        endDate: DateTime(moveIn.year + 1, moveIn.month, moveIn.day),
        rentAmount: rentAmount,
        depositAmount: depositAmount,
        status: 'active',
      );

      txn.set(_firebase.leasesCollection.doc(leaseId), lease.toMap());

      if (request.unitId != null && request.unitId!.isNotEmpty) {
        txn.update(_firebase.unitsCollection.doc(request.unitId!), {
          'occupied': true,
          'tenantId': request.tenantId,
          'status': 'occupied',
        });
      }

      if (availableUnits > 0) {
        txn.update(propRef, {'availableUnits': availableUnits - 1});
      }

      txn.update(reqRef, {
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
      });

      txn.update(_firebase.usersCollection.doc(request.tenantId), {
        'currentPropertyId': request.propertyId,
        if (request.unitId != null) 'currentUnitId': request.unitId,
      });
    });
  }
}

final leaseRepositoryProvider = Provider<LeaseRepository>((ref) {
  return LeaseRepository();
});
