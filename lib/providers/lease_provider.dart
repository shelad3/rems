import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/lease.dart';
import '../services/firestore_service.dart';

class LeaseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FirestoreService _firestore = FirestoreService.instance;
  List<Lease> _leases = [];
  List<Map<String, dynamic>> _activeLeases = [];
  bool _isLoading = false;

  List<Lease> get leases => List.unmodifiable(_leases);
  List<Map<String, dynamic>> get activeLeases =>
      _activeLeases.map((m) => Map<String, dynamic>.from(m)).toList();
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get leasesStream => _firestore.leasesRef.snapshots();

  Future<void> loadLeases() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('leases');
    _leases = maps.map((m) => Lease.fromMap(m)).toList();
    _activeLeases = await _db.getActiveLeasesWithDetails();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addLease(Lease lease) async {
    final id = await _db.insert('leases', lease.toMap());
    try {
      await _firestore.leasesRef.doc(id.toString()).set({
        ...lease.toFirestoreMap(),
        'oldLeaseId': id,
      });
    } catch (e) {
      debugPrint('Firestore addLease error: $e');
    }
    await loadLeases();
    return id;
  }

  Future<void> updateLease(Lease lease) async {
    await _db.update('leases', lease.toMap(), lease.id!);
    try {
      await _firestore.leasesRef
          .doc(lease.id.toString())
          .update(lease.toFirestoreMap());
    } catch (e) {
      debugPrint('Firestore updateLease error: $e');
    }
    await loadLeases();
  }

  Future<void> deleteLease(int id) async {
    await _db.delete('leases', id);
    try {
      await _firestore.leasesRef.doc(id.toString()).delete();
    } catch (e) {
      debugPrint('Firestore deleteLease error: $e');
    }
    await loadLeases();
  }

  List<Lease> getLeasesByTenant(int tenantId) {
    return _leases.where((l) => l.tenantId == tenantId).toList();
  }

  List<Lease> getLeasesByUnit(int unitId) {
    return _leases.where((l) => l.unitId == unitId).toList();
  }

  Lease? getActiveLeaseForUnit(int unitId) {
    try {
      final lease = _leases.firstWhere(
          (l) => l.unitId == unitId && l.isActive);
      return lease.copyWith();
    } catch (_) {
      return null;
    }
  }
}
