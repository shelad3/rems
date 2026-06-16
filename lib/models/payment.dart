class Payment {
  final int? id;
  final int leaseId;
  final int tenantId;
  final double amount;
  final DateTime paymentDate;
  final String paymentType;
  final String status;
  final String paymentMethod;
  final String? transactionId;
  final String? mpesaReceipt;
  final String? stripePaymentIntentId;
  final String paidBy;
  final double lateFee;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String notes;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.leaseId,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    this.paymentType = 'Rent',
    this.status = 'Paid',
    this.paymentMethod = 'Cash',
    this.transactionId,
    this.mpesaReceipt,
    this.stripePaymentIntentId,
    this.paidBy = 'tenant',
    this.lateFee = 0,
    this.periodStart,
    this.periodEnd,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lease_id': leaseId,
      'tenant_id': tenantId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_type': paymentType,
      'status': status,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'mpesa_receipt': mpesaReceipt,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'paid_by': paidBy,
      'late_fee': lateFee,
      'period_start': periodStart?.toIso8601String(),
      'period_end': periodEnd?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      leaseId: map['lease_id'] as int,
      tenantId: map['tenant_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentType: (map['payment_type'] as String?) ?? 'Rent',
      status: (map['status'] as String?) ?? 'Paid',
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      transactionId: map['transaction_id'] as String?,
      mpesaReceipt: map['mpesa_receipt'] as String?,
      stripePaymentIntentId: map['stripe_payment_intent_id'] as String?,
      paidBy: (map['paid_by'] as String?) ?? 'tenant',
      lateFee: ((map['late_fee'] as num?) ?? 0).toDouble(),
      periodStart: map['period_start'] != null
          ? DateTime.parse(map['period_start'] as String)
          : null,
      periodEnd: map['period_end'] != null
          ? DateTime.parse(map['period_end'] as String)
          : null,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'leaseId': leaseId,
      'tenantId': tenantId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentType': paymentType,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'mpesaReceipt': mpesaReceipt,
      'stripePaymentIntentId': stripePaymentIntentId,
      'paidBy': paidBy,
      'lateFee': lateFee,
      'periodStart': periodStart?.toIso8601String(),
      'periodEnd': periodEnd?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'oldPaymentId': id,
    };
  }

  Payment copyWith({
    int? id,
    int? leaseId,
    int? tenantId,
    double? amount,
    DateTime? paymentDate,
    String? paymentType,
    String? status,
    String? paymentMethod,
    String? transactionId,
    String? mpesaReceipt,
    String? stripePaymentIntentId,
    String? paidBy,
    double? lateFee,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? notes,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      leaseId: leaseId ?? this.leaseId,
      tenantId: tenantId ?? this.tenantId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      mpesaReceipt: mpesaReceipt ?? this.mpesaReceipt,
      stripePaymentIntentId:
          stripePaymentIntentId ?? this.stripePaymentIntentId,
      paidBy: paidBy ?? this.paidBy,
      lateFee: lateFee ?? this.lateFee,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}