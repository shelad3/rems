import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final double amount;
  final String type;
  final String method;
  final String reference;
  final String status;
  final DateTime paidAt;
  final String? receiptUrl;
  final String? notes;

  PaymentModel({
    required this.paymentId,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.amount,
    this.type = 'rent',
    this.method = 'mpesa',
    required this.reference,
    this.status = 'pending',
    DateTime? paidAt,
    this.receiptUrl,
    this.notes,
  }) : paidAt = paidAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'paymentId': paymentId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'unitId': unitId,
        'amount': amount,
        'type': type,
        'method': method,
        'reference': reference,
        'status': status,
        'paidAt': Timestamp.fromDate(paidAt),
        'receiptUrl': receiptUrl,
        'notes': notes,
      };

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      paymentId: id,
      tenantId: map['tenantId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'rent',
      method: map['method'] ?? 'mpesa',
      reference: map['reference'] ?? '',
      status: map['status'] ?? 'pending',
      paidAt: (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptUrl: map['receiptUrl'],
      notes: map['notes'],
    );
  }
}
