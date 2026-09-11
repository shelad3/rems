import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyAssignmentModel {
  final String assignmentId;
  final String propertyId;
  final String requesterId;
  final String targetUserId;
  final String type;
  final String status;
  final String message;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  PropertyAssignmentModel({
    required this.assignmentId,
    required this.propertyId,
    required this.requesterId,
    required this.targetUserId,
    required this.type,
    this.status = 'pending',
    this.message = '',
    DateTime? createdAt,
    this.reviewedBy,
    this.reviewedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'assignmentId': assignmentId,
        'propertyId': propertyId,
        'requesterId': requesterId,
        'targetUserId': targetUserId,
        'type': type,
        'status': status,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      };

  factory PropertyAssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyAssignmentModel(
      assignmentId: id,
      propertyId: map['propertyId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      type: map['type'] ?? 'manager_assignment',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: map['reviewedBy'],
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }
}