import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';
import '../services/firestore_service.dart';

class VendorProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Vendor> _vendors = [];
  bool _isLoading = false;

  List<Vendor> get vendors => _vendors;
  bool get isLoading => _isLoading;

  Future<void> loadVendors() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('vendors').get();
    _vendors = snapshot.docs
        .map((doc) =>
            Vendor.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addVendor(Vendor vendor) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('vendors').doc(id.toString()).set(
      vendor.toFirestoreMap(),
    );
    await loadVendors();
    return id;
  }

  Future<void> updateVendor(Vendor vendor) async {
    await _firestore.db
        .collection('vendors')
        .doc(vendor.id!.toString())
        .update(vendor.toFirestoreMap());
    await loadVendors();
  }

  Future<void> deleteVendor(int id) async {
    await _firestore.db.collection('vendors').doc(id.toString()).delete();
    await loadVendors();
  }

  List<Vendor> searchVendors(String query) {
    final q = query.toLowerCase();
    return _vendors.where((v) =>
      v.name.toLowerCase().contains(q) ||
      v.category.toLowerCase().contains(q) ||
      v.phone.contains(q)
    ).toList();
  }

  List<Vendor> getVendorsByCategory(String category) {
    return _vendors.where((v) => v.category == category).toList();
  }
}
