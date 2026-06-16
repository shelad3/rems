import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maintenance_request.dart';
import '../services/firestore_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<MaintenanceRequest> _requests = [];
  bool _isLoading = false;

  List<MaintenanceRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get maintenanceStream =>
      _firestore.db.collection('maintenance').snapshots();

  Future<void> loadRequests() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('maintenance').get();
    _requests = snapshot.docs
        .map((doc) => MaintenanceRequest.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addRequest(MaintenanceRequest request) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('maintenance').doc(id.toString()).set(
      request.toFirestoreMap(),
    );
    await loadRequests();
    return id;
  }

  Future<void> updateRequest(MaintenanceRequest request) async {
    await _firestore.db
        .collection('maintenance')
        .doc(request.id!.toString())
        .update(request.toFirestoreMap());
    await loadRequests();
  }

  Future<void> deleteRequest(int id) async {
    await _firestore.db.collection('maintenance').doc(id.toString()).delete();
    await loadRequests();
  }

  List<MaintenanceRequest> getRequestsByUnit(int unitId) {
    return _requests.where((r) => r.unitId == unitId).toList();
  }

  List<MaintenanceRequest> getRequestsByTenant(int tenantId) {
    return _requests.where((r) => r.tenantId == tenantId).toList();
  }

  List<MaintenanceRequest> getPendingRequests() {
    return _requests.where((r) => r.status != 'Completed').toList();
  }

  List<MaintenanceRequest> getRequestsByPriority(String priority) {
    return _requests.where((r) => r.priority == priority).toList();
  }

  List<MaintenanceRequest> getRequestsByProperty(int propertyId) {
    return _requests.where((r) => r.unitId == propertyId).toList();
  }
}
