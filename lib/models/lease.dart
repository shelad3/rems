class Lease {
  final int? id;
  final int unitId;
  final int tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final double rentAmount;
  final double securityDeposit;
  final bool isActive;
  final String notes;
  final DateTime createdAt;

  Lease({
    this.id,
    required this.unitId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    this.rentAmount = 0,
    this.securityDeposit = 0,
    this.isActive = true,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'rent_amount': rentAmount,
      'security_deposit': securityDeposit,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Lease.fromMap(Map<String, dynamic> map) {
    return Lease(
      id: map['id'] as int?,
      unitId: map['unit_id'] as int,
      tenantId: map['tenant_id'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      rentAmount: (map['rent_amount'] as num?)?.toDouble() ?? 0,
      securityDeposit: (map['security_deposit'] as num?)?.toDouble() ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Lease.fromFirestore(Map<String, dynamic> map, String docId) {
    return Lease(
      id: int.tryParse(docId),
      unitId: int.tryParse(map['unitId'].toString()) ?? 0,
      tenantId: int.tryParse(map['tenantId'].toString()) ?? 0,
      startDate: DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] as String? ?? '') ?? DateTime.now(),
      rentAmount: double.tryParse(map['rentAmount'].toString()) ?? 0,
      securityDeposit: double.tryParse(map['securityDeposit'].toString()) ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'unitId': unitId,
      'tenantId': tenantId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Lease copyWith({
    int? id,
    int? unitId,
    int? tenantId,
    DateTime? startDate,
    DateTime? endDate,
    double? rentAmount,
    double? securityDeposit,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return Lease(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentAmount: rentAmount ?? this.rentAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
