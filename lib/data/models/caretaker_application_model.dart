import 'package:cloud_firestore/cloud_firestore.dart';

class CaretakerApplicationModel {
  final String applicationId;
  final String propertyId;
  final String caretakerId;
  final String status;
  final String message;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? notes;

  CaretakerApplicationModel({
    required this.applicationId,
    required this.propertyId,
    required this.caretakerId,
    this.status = 'pending',
    this.message = '',
    DateTime? createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'applicationId': applicationId,
        'propertyId': propertyId,
        'caretakerId': caretakerId,
        'status': status,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
        'notes': notes,
      };

  factory CaretakerApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return CaretakerApplicationModel(
      applicationId: id,
      propertyId: map['propertyId'] ?? '',
      caretakerId: map['caretakerId'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: map['reviewedBy'],
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
    );
  }
}