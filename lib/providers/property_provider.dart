import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../services/firestore_service.dart';

class PropertyProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Property> _properties = [];
  List<Unit> _units = [];
  Map<String, String> _ownerNames = {};
  bool _isLoading = false;

  List<Property> get properties => _properties;
  List<Unit> get units => _units;
  Map<String, String> get ownerNames => _ownerNames;
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get propertiesStream =>
      _firestore.db.collection('properties').snapshots();
  Stream<QuerySnapshot> get allUnitsStream =>
      _firestore.db.collection('units').snapshots();

  Future<void> loadProperties() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('properties').get();
    _properties = snapshot.docs
        .map((doc) =>
            Property.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    await _loadOwnerNames();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadOwnerNames() async {
    _ownerNames = {};
    final snapshot = await _firestore.db.collection('owners').get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _ownerNames[doc.id] = data['name'] as String? ?? 'Unknown Owner';
    }
  }

  Future<void> loadUnitsByProperty(int propertyId) async {
    final snapshot = await _firestore.db
        .collection('units')
        .where('propertyId', isEqualTo: propertyId)
        .get();
    _units = snapshot.docs
        .map((doc) =>
            Unit.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    notifyListeners();
  }

  Future<int> addProperty(Property property) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db
        .collection('properties')
        .doc(id.toString())
        .set(property.toFirestoreMap());
    await loadProperties();
    return id;
  }

  Future<void> updateProperty(Property property) async {
    await _firestore.db
        .collection('properties')
        .doc(property.id!.toString())
        .update(property.toFirestoreMap());
    await loadProperties();
  }

  Future<void> deleteProperty(int id) async {
    await _firestore.db.collection('properties').doc(id.toString()).delete();
    await loadProperties();
  }

  Future<void> addUnit(Unit unit) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db
        .collection('units')
        .doc(id.toString())
        .set(unit.toFirestoreMap());
    await loadUnitsByProperty(unit.propertyId);
  }

  Future<void> updateUnit(Unit unit) async {
    await _firestore.db
        .collection('units')
        .doc(unit.id!.toString())
        .update(unit.toFirestoreMap());
    await loadUnitsByProperty(unit.propertyId);
  }

  Future<void> deleteUnit(int id, int propertyId) async {
    await _firestore.db.collection('units').doc(id.toString()).delete();
    await loadUnitsByProperty(propertyId);
  }

  List<Property> searchProperties(String query) {
    final q = query.toLowerCase();
    return _properties.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.address.toLowerCase().contains(q) ||
      p.city.toLowerCase().contains(q)
    ).toList();
  }

  Property? getPropertyById(int id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String getOwnerName(int ownerId) {
    return _ownerNames[ownerId.toString()] ?? 'Unknown Owner';
  }

  int getOccupiedUnits(int propertyId) {
    return _units.where((u) => u.isOccupied).length;
  }
}
