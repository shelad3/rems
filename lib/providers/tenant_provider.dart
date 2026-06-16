import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/tenant.dart';
import '../services/firestore_service.dart';

class TenantProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirestoreService _firestore = FirestoreService.instance;
  List<Tenant> _tenants = [];
  bool _isLoading = false;

  List<Tenant> get tenants => List.unmodifiable(_tenants);
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get tenantsStream =>
      FirebaseFirestore.instance.collection('tenants').snapshots();

  Future<void> loadTenants() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('tenants');
    _tenants = maps.map((m) => Tenant.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addTenant(Tenant tenant) async {
    final id = await _db.insert('tenants', tenant.toMap());
    try {
      await _firestore.db.collection('tenants').doc(id.toString()).set({
        ...tenant.toFirestoreMap(),
        'oldTenantId': id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firestore addTenant error: $e');
    }
    await loadTenants();
    return id;
  }

  Future<void> updateTenant(Tenant tenant) async {
    await _db.update('tenants', tenant.toMap(), tenant.id!);
    try {
      await _firestore.db
          .collection('tenants')
          .doc(tenant.id.toString())
          .update(tenant.toFirestoreMap());
    } catch (e) {
      debugPrint('Firestore updateTenant error: $e');
    }
    await loadTenants();
  }

  Future<void> deleteTenant(int id) async {
    await _db.delete('tenants', id);
    try {
      await _firestore.db.collection('tenants').doc(id.toString()).delete();
    } catch (e) {
      debugPrint('Firestore deleteTenant error: $e');
    }
    await loadTenants();
  }

  Future<List<Tenant>> searchTenants(String query) async {
    final maps = await _db.searchTenants(query);
    return maps.map((m) => Tenant.fromMap(m)).toList();
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
