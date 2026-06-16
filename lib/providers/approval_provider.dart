import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/approval.dart';
import '../services/firestore_service.dart';

class ApprovalProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Approval> _approvals = [];
  bool _isLoading = false;

  List<Approval> get approvals => _approvals;
  List<Approval> get pendingApprovals =>
      _approvals.where((a) => a.status == 'Pending').toList();
  bool get isLoading => _isLoading;

  Future<void> loadApprovals() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('approvals').get();
    _approvals = snapshot.docs
        .map((doc) =>
            Approval.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addApproval(Approval approval) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('approvals').doc(id.toString()).set(
      approval.toFirestoreMap(),
    );
    await loadApprovals();
  }

  Future<void> reviewApproval(
      int id, String status, String reviewedBy, String reviewNotes) async {
    await _firestore.db.collection('approvals').doc(id.toString()).update({
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
    await loadApprovals();
  }

  Future<void> deleteApproval(int id) async {
    await _firestore.db.collection('approvals').doc(id.toString()).delete();
    await loadApprovals();
  }

  int get pendingCount => pendingApprovals.length;
}
