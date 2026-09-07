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

  /// Properties assigned to a caretaker (via managerId/caretakerId).
  Stream<List<PropertyModel>> getPropertiesByCaretaker(String caretakerId) {
    return _firebase.propertiesCollection
        .where('managerId', isEqualTo: caretakerId)
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

  Future<void> assignCaretaker(
      String propertyId, String? caretakerId) async {
    await _firebase.propertiesCollection.doc(propertyId).update({
      'managerId': caretakerId,
      'caretakerId': caretakerId,
    });
  }

  Future<void> assignOwner(String propertyId, String ownerId) async {
    await _firebase.propertiesCollection
        .doc(propertyId)
        .update({'ownerId': ownerId});
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
