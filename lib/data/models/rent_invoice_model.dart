import 'package:cloud_firestore/cloud_firestore.dart';

class RentInvoiceModel {
  final String invoiceId;
  final String tenantId;
  final String propertyId;
  final String unitId;
  final DateTime periodStart;
  final String periodKey;
  final double amount;
  final double amountPaid;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  RentInvoiceModel({
    required this.invoiceId,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.periodStart,
    required this.periodKey,
    required this.amount,
    this.amountPaid = 0,
    this.status = 'unpaid',
    DateTime? createdAt,
    this.paidAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get outstanding =>
      (amount - amountPaid).clamp(0.0, double.infinity).toDouble();

  bool get isPaid => amountPaid >= amount;

  Map<String, dynamic> toMap() => {
        'invoiceId': invoiceId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'unitId': unitId,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodKey': periodKey,
        'amount': amount,
        'amountPaid': amountPaid,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      };

  factory RentInvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return RentInvoiceModel(
      invoiceId: id,
      tenantId: map['tenantId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      unitId: map['unitId'] ?? '',
      periodStart: (map['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodKey: map['periodKey'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      status: map['status'] ?? 'unpaid',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  RentInvoiceModel copyWith({
    double? amountPaid,
    String? status,
    DateTime? paidAt,
  }) {
    return RentInvoiceModel(
      invoiceId: invoiceId,
      tenantId: tenantId,
      propertyId: propertyId,
      unitId: unitId,
      periodStart: periodStart,
      periodKey: periodKey,
      amount: amount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}