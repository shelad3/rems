import 'package:cloud_firestore/cloud_firestore.dart';

class LeaseModel {
  final String leaseId;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final double rentAmount;
  final double depositAmount;
  final String status;
  final bool termsAccepted;
  final String? signedPdfUrl;
  final DateTime createdAt;

  LeaseModel({
    required this.leaseId,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.startDate,
    required this.endDate,
    required this.rentAmount,
    required this.depositAmount,
    this.status = 'active',
    this.termsAccepted = false,
    this.signedPdfUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'leaseId': leaseId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'unitId': unitId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'rentAmount': rentAmount,
        'depositAmount': depositAmount,
        'status': status,
        'termsAccepted': termsAccepted,
        'signedPdfUrl': signedPdfUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory LeaseModel.fromMap(Map<String, dynamic> map, String id) {
    return LeaseModel(
      leaseId: id,
      tenantId: map['tenantId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rentAmount: (map['rentAmount'] ?? 0).toDouble(),
      depositAmount: (map['depositAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'active',
      termsAccepted: map['termsAccepted'] ?? false,
      signedPdfUrl: map['signedPdfUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
