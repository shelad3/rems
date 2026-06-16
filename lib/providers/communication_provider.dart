import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/communication_log.dart';
import '../services/firestore_service.dart';

class CommunicationProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<CommunicationLog> _logs = [];
  bool _isLoading = false;

  List<CommunicationLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadAllLogs() async {
    _isLoading = true;
    notifyListeners();
    final snapshot =
        await _firestore.db.collection('communication_logs').get();
    _logs = snapshot.docs
        .map((doc) => CommunicationLog.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLogsByTarget({
    int? propertyId,
    int? tenantId,
    int? ownerId,
  }) async {
    _isLoading = true;
    notifyListeners();
    await loadAllLogs();
    _logs = _logs.where((log) {
      if (propertyId != null && log.propertyId != propertyId) return false;
      if (tenantId != null && log.tenantId != tenantId) return false;
      if (ownerId != null && log.ownerId != ownerId) return false;
      return true;
    }).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(CommunicationLog log) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db
        .collection('communication_logs')
        .doc(id.toString())
        .set(log.toFirestoreMap());
    await loadAllLogs();
  }

  Future<void> deleteLog(int id) async {
    await _firestore.db
        .collection('communication_logs')
        .doc(id.toString())
        .delete();
    await loadAllLogs();
  }
}
