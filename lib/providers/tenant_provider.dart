import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';

class TenantProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Tenant> _tenants = [];
  bool _isLoading = false;

  List<Tenant> get tenants => List.unmodifiable(_tenants);
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get tenantsStream =>
      _firestore.db.collection('tenants').snapshots();

  Future<void> loadTenants() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('tenants').get();
    _tenants = snapshot.docs
        .map((doc) =>
            Tenant.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addTenant(Tenant tenant) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('tenants').doc(id.toString()).set(
      tenant.toFirestoreMap(),
    );
    await loadTenants();
    return id;
  }

  Future<void> updateTenant(Tenant tenant) async {
    await _firestore.db
        .collection('tenants')
        .doc(tenant.id!.toString())
        .update(tenant.toFirestoreMap());
    await loadTenants();
  }

  Future<void> deleteTenant(int id) async {
    await _firestore.db.collection('tenants').doc(id.toString()).delete();
    await loadTenants();
  }

  List<Tenant> searchTenants(String query) {
    final q = query.toLowerCase();
    return _tenants
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q) ||
            t.phone.contains(q))
        .toList();
  }

  Tenant? getTenantById(int id) {
    try {
      final tenant = _tenants.firstWhere((t) => t.id == id);
      return tenant.copyWith();
    } catch (_) {
      return null;
    }
  }
}
