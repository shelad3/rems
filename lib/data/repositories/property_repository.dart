import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../models/unit_model.dart';
import '../services/firebase_service.dart';

class PropertyRepository {
  final FirebaseService _firebase = FirebaseService();

  Stream<List<PropertyModel>> getProperties() {
    return _firebase.propertiesCollection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<PropertyModel>> getPropertiesByOwner(String ownerId) {
    return _firebase.propertiesCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<PropertyModel>> getPropertiesByManager(String managerId) {
    return _firebase.propertiesCollection
        .where('managerId', isEqualTo: managerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Properties assigned to a caretaker (via caretakerId).
  Stream<List<PropertyModel>> getPropertiesByCaretaker(String caretakerId) {
    return _firebase.propertiesCollection
        .where('caretakerId', isEqualTo: caretakerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<PropertyModel?> getPropertyById(String propertyId) {
    return _firebase.propertiesCollection.doc(propertyId).snapshots().map(
      (snapshot) => snapshot.exists
          ? PropertyModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id)
          : null,
    );
  }

  Stream<List<UnitModel>> getUnitsByProperty(String propertyId) {
    return _firebase.unitsCollection
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnitModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<UnitModel>> getAvailableUnits(String propertyId) {
    return _firebase.unitsCollection
        .where('propertyId', isEqualTo: propertyId)
        .where('occupied', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnitModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<UnitModel?> getUnitById(String unitId) {
    return _firebase.unitsCollection.doc(unitId).snapshots().map(
      (snapshot) => snapshot.exists
          ? UnitModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id)
          : null,
    );
  }

  Stream<List<UnitModel>> streamAllUnits() {
    return _firebase.unitsCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UnitModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> createProperty(PropertyModel property) async {
    await _firebase.propertiesCollection.doc(property.propertyId).set(property.toMap());
  }

  Future<void> createUnit(UnitModel unit) async {
    await _firebase.unitsCollection.doc(unit.unitId).set(unit.toMap());
  }

  Future<void> updateUnit(String unitId, Map<String, dynamic> data) async {
    await _firebase.unitsCollection.doc(unitId).update(data);
  }

  Future<void> deleteUnit(String unitId) async {
    await _firebase.unitsCollection.doc(unitId).delete();
  }

  Future<void> assignCaretaker(String propertyId, String? caretakerId) async {
    await _firebase.propertiesCollection.doc(propertyId).update({
      'caretakerId': caretakerId,
    });
  }

  Future<void> assignOwner(String propertyId, String ownerId) async {
    await _firebase.propertiesCollection
        .doc(propertyId)
        .update({'ownerId': ownerId});
  }

  Future<void> appointCaretaker({
    required String propertyId,
    required String caretakerId,
    required String applicationId,
    String? reviewedBy,
  }) async {
    await _firebase.firestore.runTransaction((txn) async {
      final propRef = _firebase.propertiesCollection.doc(propertyId);
      final appRef = _firebase.caretakerApplicationsCollection.doc(applicationId);
      txn.update(propRef, {'caretakerId': caretakerId, 'caretakerHiringOpen': false});
      txn.update(appRef, {
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
      });
    });
  }

  Future<void> applyAssignment({
    required String assignmentId,
    required String propertyId,
    required String type,
    required String userId,
    String? reviewedBy,
  }) async {
    await _firebase.firestore.runTransaction((txn) async {
      final propRef = _firebase.propertiesCollection.doc(propertyId);
      final assRef =
          _firebase.propertyAssignmentsCollection.doc(assignmentId);
      if (type == 'owner_assignment') {
        txn.update(propRef, {'ownerId': userId});
      } else {
        txn.update(propRef, {'managerId': userId});
      }
      txn.update(assRef, {
        'status': 'approved',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
      });
    });
  }

  Future<void> updateUnitsCount(String propertyId, int totalUnits, int availableUnits) async {
    await _firebase.propertiesCollection.doc(propertyId).update({
      'totalUnits': totalUnits,
      'availableUnits': availableUnits,
    });
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) async {
    await _firebase.propertiesCollection.doc(propertyId).update(data);
  }

  Future<List<PropertyModel>> getAllProperties() async {
    final snapshot = await _firebase.propertiesCollection.get();
    return snapshot.docs
        .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Stream<List<PropertyModel>> streamAllProperties() {
    return _firebase.propertiesCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository();
});
