import 'package:cloud_firestore/cloud_firestore.dart';

class AccessRequestModel {
  final String requestId;
  final String tenantId;
  final String propertyId;
  final String? unitId;
  final String status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? notes;
  final String? desiredMoveInDate;
  final String? tenantName;
  final String? tenantPhone;
  final String? tenantEmail;

  AccessRequestModel({
    required this.requestId,
    required this.tenantId,
    required this.propertyId,
    this.unitId,
    this.status = 'pending',
    DateTime? requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.notes,
    this.desiredMoveInDate,
    this.tenantName,
    this.tenantPhone,
    this.tenantEmail,
  }) : requestedAt = requestedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'unitId': unitId,
        'status': status,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'notes': notes,
        'desiredMoveInDate': desiredMoveInDate,
        'tenantName': tenantName,
        'tenantPhone': tenantPhone,
        'tenantEmail': tenantEmail,
      };

  factory AccessRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return AccessRequestModel(
      requestId: id,
      tenantId: map['tenantId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'],
      status: map['status'] ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: map['reviewedBy'],
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      desiredMoveInDate: map['desiredMoveInDate'],
      tenantName: map['tenantName'],
      tenantPhone: map['tenantPhone'],
      tenantEmail: map['tenantEmail'],
    );
  }

  AccessRequestModel copyWith({String? status, String? reviewedBy, DateTime? reviewedAt, String? notes}) {
    return AccessRequestModel(
      requestId: requestId,
      tenantId: tenantId,
      propertyId: propertyId,
      unitId: unitId,
      status: status ?? this.status,
      requestedAt: requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      notes: notes ?? this.notes,
      desiredMoveInDate: desiredMoveInDate,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      tenantEmail: tenantEmail,
    );
  }
}
