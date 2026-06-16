import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lease.dart';
import '../services/firestore_service.dart';

class LeaseProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Lease> _leases = [];
  bool _isLoading = false;

  List<Lease> get leases => List.unmodifiable(_leases);
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get leasesStream =>
      _firestore.db.collection('leases').snapshots();

  Future<void> loadLeases() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('leases').get();
    _leases = snapshot.docs
        .map((doc) =>
            Lease.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addLease(Lease lease) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('leases').doc(id.toString()).set(
      lease.toFirestoreMap(),
    );
    await loadLeases();
    return id;
  }

  Future<void> updateLease(Lease lease) async {
    await _firestore.db
        .collection('leases')
        .doc(lease.id!.toString())
        .update(lease.toFirestoreMap());
    await loadLeases();
  }

  Future<void> deleteLease(int id) async {
    await _firestore.db.collection('leases').doc(id.toString()).delete();
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
