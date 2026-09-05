import 'package:cloud_firestore/cloud_firestore.dart';

class MpesaRequestModel {
  final String checkoutRequestId;
  final String tenantUid;
  final String propertyId;
  final String? unitId;
  final double amount;
  final String intent;
  final String status;
  final String? receipt;
  final DateTime createdAt;
  final DateTime? paidAt;

  MpesaRequestModel({
    required this.checkoutRequestId,
    required this.tenantUid,
    required this.propertyId,
    this.unitId,
    required this.amount,
    this.intent = 'rent',
    this.status = 'pending',
    this.receipt,
    DateTime? createdAt,
    this.paidAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'checkoutRequestId': checkoutRequestId,
        'tenantUid': tenantUid,
        'propertyId': propertyId,
        'unitId': unitId,
        'amount': amount,
        'intent': intent,
        'status': status,
        'receipt': receipt,
        'createdAt': Timestamp.fromDate(createdAt),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      };

  factory MpesaRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return MpesaRequestModel(
      checkoutRequestId: map['checkoutRequestId'] ?? id,
      tenantUid: map['tenantUid'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'],
      amount: (map['amount'] ?? 0).toDouble(),
      intent: map['intent'] ?? 'rent',
      status: map['status'] ?? 'pending',
      receipt: map['receipt'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}