import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String logId;
  final String actorId;
  final String action;
  final String targetType;
  final String targetId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AuditLogModel({
    required this.logId,
    required this.actorId,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'logId': logId,
        'actorId': actorId,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      logId: id,
      actorId: map['actorId'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
