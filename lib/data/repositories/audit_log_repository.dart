import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log_model.dart';
import '../services/firebase_service.dart';

class AuditLogRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> log({
    required String actorId,
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final doc = _firebase.auditLogsCollection.doc();
    await doc.set(AuditLogModel(
      logId: doc.id,
      actorId: actorId,
      action: action,
      targetType: targetType,
      targetId: targetId,
      metadata: metadata,
    ).toMap());
  }

  Stream<List<AuditLogModel>> streamLogs() {
    return _firebase.auditLogsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<List<AuditLogModel>> getLogs({int limit = 50}) async {
    final snapshot = await _firebase.auditLogsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => AuditLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<int> countLogsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snapshot = await _firebase.auditLogsCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    return snapshot.docs.length;
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository();
});
